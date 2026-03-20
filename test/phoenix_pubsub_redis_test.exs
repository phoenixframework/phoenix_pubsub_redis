Application.put_env(
  :phoenix_pubsub,
  :test_adapter,
  {Phoenix.PubSub.Redis,
   url: System.get_env("REDIS_URL", "redis://localhost:6379"),
   node_name: :SAMPLE,
   compression_level: 1}
)

Code.require_file("#{Mix.Project.deps_paths()[:phoenix_pubsub]}/test/shared/pubsub_test.exs")
