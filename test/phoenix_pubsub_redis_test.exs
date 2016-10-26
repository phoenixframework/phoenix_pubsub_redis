# Turn node into a distributed node with the given long name
case :net_kernel.start([:"redis@127.0.0.1"]) do
  {:ok, _pid} -> :ok
  other -> raise """
  unable to start redis tests. Is epmd running and daemonized?
  You may need to run `$ epmd -daemon`.

      #{inspect other}
  """
end

Application.put_env(:phoenix, :pubsub_test_adapter, Phoenix.PubSub.Redis)
Code.require_file "../deps/phoenix_pubsub/test/shared/pubsub_test.exs", __DIR__
