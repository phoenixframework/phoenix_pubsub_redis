defmodule Phoenix.PubSub.RedisServer do
  @moduledoc false

  use GenServer
  require Logger

  @reconnect_after_ms 5_000
  @redis_msg_vsn 3

  ## Adapter callbacks

  def node_name(adapter_name) do
    :ets.lookup_element(adapter_name, :node_name, 2)
  end

  def broadcast(adapter_name, topic, message, dispatcher) do
    publish(adapter_name, :except, node_name(adapter_name), topic, message, dispatcher)
  end

  def direct_broadcast(adapter_name, node_name, topic, message, dispatcher) do
    publish(adapter_name, :only, node_name, topic, message, dispatcher)
  end

  defp publish(adapter_name, mode, node_name, topic, message, dispatcher) do
    namespace = redis_namespace(adapter_name)
    compression_level = compression_level(adapter_name)
    redis_msg = {@redis_msg_vsn, mode, node_name, topic, message, dispatcher}
    bin_msg = :erlang.term_to_binary(redis_msg, compressed: compression_level)

    :poolboy.transaction(adapter_name, fn worker_pid ->
      case Redix.command(worker_pid, ["PUBLISH", namespace, bin_msg]) do
        {:ok, _} ->
          :ok

        {:error, %Redix.ConnectionError{reason: :closed}} ->
          Logger.error("failed to publish broadcast due to closed redis connection")
          :ok

        {:error, reason} ->
          {:error, reason}
      end
    end)
  end

  defp compression_level(adapter_name) do
    :ets.lookup_element(adapter_name, :compression_level, 2)
  end

  ## Server callbacks

  def start_link({_, adapter_name, _, _} = state) do
    GenServer.start_link(__MODULE__, state, name: Module.concat(adapter_name, "Server"))
  end

  def init({pubsub_name, adapter_name, node_name, redis_opts}) do
    Process.flag(:trap_exit, true)

    state = %{
      pubsub_name: pubsub_name,
      adapter_name: adapter_name,
      node_name: node_name,
      redix_pid: nil,
      reconnect_timer: nil,
      redis_opts: [sync_connect: true] ++ redis_opts
    }

    {:ok, establish_conn(state)}
  end

  def handle_info(:establish_conn, state) do
    {:noreply, establish_conn(%{state | reconnect_timer: nil})}
  end

  def handle_info(
        {:redix_pubsub, redix_pid, _reference, :subscribed, _},
        %{redix_pid: redix_pid} = state
      ) do
    {:noreply, state}
  end

  def handle_info(
        {:redix_pubsub, redix_pid, _reference, :disconnected, %{error: %{reason: reason}}},
        %{redix_pid: redix_pid} = state
      ) do
    Logger.error(
      "Phoenix.PubSub disconnected from Redis with reason #{inspect(reason)} (awaiting reconnection)"
    )

    {:noreply, state}
  end

  def handle_info(
        {:redix_pubsub, redix_pid, _reference, :message, %{payload: bin_msg}},
        %{redix_pid: redix_pid, node_name: node_name, pubsub_name: pubsub_name} = state
      ) do
    case :erlang.binary_to_term(bin_msg) do
      {@redis_msg_vsn, mode, target_node, topic, message, dispatcher}
      when mode == :only and target_node == node_name
      when mode == :except and target_node != node_name ->
        Phoenix.PubSub.local_broadcast(pubsub_name, topic, message, dispatcher)

      _ ->
        :ignore
    end

    {:noreply, state}
  end

  def handle_info({:EXIT, redix_pid, _}, %{redix_pid: redix_pid} = state) do
    {:noreply, establish_conn(state)}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp establish_failed(state) do
    Logger.error("unable to establish initial redis connection. Attempting to reconnect...")
    %{state | redix_pid: nil, reconnect_timer: schedule_reconnect(state)}
  end

  defp schedule_reconnect(%{reconnect_timer: timer}) do
    timer && Process.cancel_timer(timer)
    Process.send_after(self(), :establish_conn, @reconnect_after_ms)
  end

  defp establish_success(%{redix_pid: redix_pid, adapter_name: adapter_name} = state) do
    {:ok, _reference} = Redix.PubSub.subscribe(redix_pid, redis_namespace(adapter_name), self())
    state
  end

  defp establish_conn(%{redis_opts: redis_opts} = state) do
    case Redix.PubSub.start_link(redis_opts) do
      {:ok, redix_pid} ->
        establish_success(%{state | redix_pid: redix_pid})

      {:error, _} ->
        establish_failed(state)
    end
  end

  defp redis_namespace(adapter_name), do: "phx:#{adapter_name}"
end
