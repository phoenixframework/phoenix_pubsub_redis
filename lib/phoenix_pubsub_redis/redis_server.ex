defmodule Phoenix.PubSub.RedisServer do
  @moduledoc false

  use GenServer
  require Logger
  alias Phoenix.PubSub.Local

  @reconnect_after_ms 5_000
  @redis_msg_vsn 1
  @redix_opts [:host, :port, :password, :database]

  @doc """
  Starts the server
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Dict.fetch!(opts, :name))
  end

  @doc false
  def direct_broadcast(fastlane, pool_name, pool_size, namespace, node_ref, _node_name, from_pid, topic, msg) do
    do_broadcast(fastlane, pool_name, pool_size, namespace, node_ref, from_pid, topic, msg)
  end

  @doc false
  def broadcast(fastlane, pool_name, pool_size, namespace, node_ref, from_pid, topic, msg) do
    do_broadcast(fastlane, pool_name, pool_size, namespace, node_ref, from_pid, topic, msg)
  end

  defp do_broadcast(fastlane, pool_name, pool_size, namespace, node_ref, from_pid, topic, msg) do
    redis_msg = {@redis_msg_vsn, node_ref, fastlane, pool_size, from_pid, topic, msg}
    bin_msg   = :erlang.term_to_binary(redis_msg)

    :poolboy.transaction pool_name, fn worker_pid ->
      case Redix.command(worker_pid, ["PUBLISH", namespace, bin_msg]) do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Initializes the server.

  An initial connection establishment loop is entered. Once `:redix`
  is started successfully, it handles reconnections automatically, so we
  pass off reconnection handling once we find an initial connection.
  """
  def init(opts) do
    Process.flag(:trap_exit, true)
    state = %{server_name: Keyword.fetch!(opts, :server_name),
              pool_name: Keyword.fetch!(opts, :pool_name),
              namespace: Keyword.fetch!(opts, :namespace),
              node_ref: Keyword.fetch!(opts, :node_ref),
              redix_pid: nil,
              status: :disconnected,
              reconnect_timer: nil,
              opts: opts}

    {:ok, establish_conn(state)}
  end

  def handle_info(:establish_conn, state) do
    {:noreply, establish_conn(%{state | reconnect_timer: nil})}
  end

  def handle_info({:redix_pubsub, redix_pid, :subscribed, _}, %{redix_pid: redix_pid} = state) do
    {:noreply, state}
  end

  def handle_info({:redix_pubsub, redix_pid, :message, %{payload: bin_msg}}, %{redix_pid: redix_pid} = state) do
    {_vsn, remote_node_ref, fastlane, pool_size, from_pid, topic, msg} = :erlang.binary_to_term(bin_msg)

    if remote_node_ref == state.node_ref do
      Local.broadcast(fastlane, state.server_name, pool_size, from_pid, topic, msg)
    else
      Local.broadcast(fastlane, state.server_name, pool_size, :none, topic, msg)
    end

    {:noreply, state}
  end

  def handle_info({:EXIT, redix_pid, _}, %{redix_pid: redix_pid} = state) do
    {:noreply, establish_conn(state)}
  end

  def handle_info({:EXIT, _, _reason}, state) do
    {:noreply, state}
  end

  @doc """
  Connection establishment and shutdown loop

  On init, an initial conection to redis is attempted when starting `:redix`
  """
  def terminate(_reason, _state) do
    :ok
  end

  defp establish_failed(state) do
    Logger.error "unable to establish initial redis connection. Attempting to reconnect..."
    %{state | redix_pid: nil,
              reconnect_timer: schedule_reconnect(state),
              status: :disconnected}
  end

  defp schedule_reconnect(state) do
    if state.reconnect_timer, do: :timer.cancel(state.reconnect_timer)
    {:ok, timer} = :timer.send_after(@reconnect_after_ms, :establish_conn)

    timer
  end

  defp establish_success(%{redix_pid: redix_pid} = state) do
    :ok = Redix.PubSub.subscribe(redix_pid, state.namespace, self())
    %{state | status: :connected}
  end

  defp establish_conn(state) do
    redis_opts = Keyword.take(state.opts, @redix_opts)
    case Redix.PubSub.start_link(redis_opts, sync_connect: true) do
      {:ok, redix_pid} -> establish_success(%{state | redix_pid: redix_pid})
      {:error, _} ->
        establish_failed(state)
    end
  end
end
