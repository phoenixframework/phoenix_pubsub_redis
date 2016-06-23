defmodule Phoenix.PubSub.RedisServer do
  @moduledoc false

  use GenServer
  require Logger
  alias Phoenix.PubSub.Local

  @reconnect_after_ms 5_000
  @redis_msg_vsn 1

  @doc """
  Starts the server
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Dict.fetch!(opts, :name))
  end

  @doc """
  Broadcasts message to redis. To be only called from {:perform, {m, f, a}}
  response to clients
  """
  def broadcast(pool_name, pool_size, namespace, node_ref, from_pid, topic, msg) do
    redis_msg = {@redis_msg_vsn, node_ref, pool_size, from_pid, topic, msg}
    bin_msg   = :erlang.term_to_binary(redis_msg)

    :poolboy.transaction pool_name, fn worker_pid ->
      case GenServer.call(worker_pid, :conn) do
        {:ok, conn_pid} ->
          case :redo.cmd(conn_pid, ["PUBLISH", namespace, bin_msg]) do
            {:error, reason} -> {:error, reason}
            _ -> :ok
          end

        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Initializes the server.

  An initial connection establishment loop is entered. Once `:redo`
  is started successfully, it handles reconnections automatically, so we
  pass off reconnection handling once we find an initial connection.
  """
  def init(opts) do
    Process.flag(:trap_exit, true)

    state = %{server_name: Keyword.fetch!(opts, :server_name),
              pool_name: Keyword.fetch!(opts, :pool_name),
              namespace: Keyword.fetch!(opts, :namespace),
              node_ref: Keyword.fetch!(opts, :node_ref),
              redo_pid: nil,
              redo_ref: nil,
              status: :disconnected,
              reconnect_timer: nil,
              opts: opts}

    {:ok, establish_conn(state)}
  end

  def handle_info({ref, ["subscribe", _, _]}, %{redo_ref: ref} = state) do
    {:noreply, state}
  end

  def handle_info({ref, ["message", _redis_topic, bin_msg]}, %{redo_ref: ref} = state) do
    {_vsn, remote_node_ref, pool_size, from_pid, topic, msg} = :erlang.binary_to_term(bin_msg)

    if remote_node_ref == state.node_ref do
      Local.broadcast(nil, state.server_name, pool_size, from_pid, topic, msg)
    else
      Local.broadcast(nil, state.server_name, pool_size, :none, topic, msg)
    end

    {:noreply, state}
  end

  def handle_info({ref, :closed}, %{redo_ref: ref} = state) do
    :ok = :redo.shutdown(state.redo_pid)
    {:noreply, establish_failed(state)}
  end
  def handle_info({_ref, :closed}, state) do
    {:noreply, state}
  end

  def handle_info({:EXIT, redo_pid, _}, %{redo_pid: redo_pid} = state) do
    {:noreply, establish_failed(state)}
  end
  def handle_info({:EXIT, _, {:error, :econnrefused}}, state) do
    {:noreply, establish_failed(state)}
  end
  def handle_info({:EXIT, _, _reason}, state) do
    {:noreply, state}
  end

  @doc """
  Connection establishment and shutdown loop

  On init, an initial conection to redis is attempted when starting `:redo`
  """
  def handle_info(:establish_conn, state) do
    {:noreply, establish_conn(%{state | reconnect_timer: nil})}
  end

  def terminate(_reason, %{status: :disconnected}) do
    :ok
  end
  def terminate(_reason, state) do
    :redo.shutdown(state.redo_pid)
    :ok
  end

  defp establish_failed(%{reconnect_timer: t} = state) when not is_nil(t) do
    state
  end
  defp establish_failed(state) do
    Logger.error "unable to establish redis connection. Attempting to reconnect..."
    %{state | redo_pid: nil,
              redo_ref: nil,
              reconnect_timer: schedule_reconnect(state),
              status: :disconnected}
  end
  defp establish_success(redo_pid, state) do
    ref = :redo.subscribe(redo_pid, state.namespace)
    %{state | redo_pid: redo_pid,
              redo_ref: ref,
              status: :connected}
  end

  defp schedule_reconnect(state) do
    if state.reconnect_timer, do: :timer.cancel(state.reconnect_timer)
    {:ok, timer} = :timer.send_after(@reconnect_after_ms, :establish_conn)

    timer
  end

  def establish_conn(state) do
    case :redo.start_link(:undefined, state.opts) do
      {:ok, redo_pid} -> establish_success(redo_pid, state)
      _error          -> establish_failed(state)
    end
  end

end
