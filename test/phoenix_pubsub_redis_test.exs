Application.put_env(:phoenix_pubsub, :test_adapter, {Phoenix.PubSub.Redis, node_name: :SAMPLE, compression_level: 1})
Code.require_file "#{Mix.Project.deps_paths[:phoenix_pubsub]}/test/shared/pubsub_test.exs"
