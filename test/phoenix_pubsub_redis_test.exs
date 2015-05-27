Application.put_env(:phoenix, :pubsub_test_adapter, Phoenix.PubSub.Redis)
Code.require_file "../deps/phoenix/test/support/pubsub_setup.exs", __DIR__
