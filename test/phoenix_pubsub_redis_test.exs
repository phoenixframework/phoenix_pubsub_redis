Application.put_env(:phoenix, :pubsub_test_adapter, Phoenix.PubSub.Redis)
Code.require_file "../deps/phoenix_pubsub/test/shared/pubsub_test.exs", __DIR__
