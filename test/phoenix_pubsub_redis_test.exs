Application.put_env(
  :phoenix_pubsub,
  :test_adapter,
  {Phoenix.PubSub.Redis,
   redis_opts: System.get_env("REDIS_URL", "redis://localhost:6379"),
   node_name: :SAMPLE,
   compression_level: 1}
)

Code.require_file("#{Mix.Project.deps_paths()[:phoenix_pubsub]}/test/shared/pubsub_test.exs")

defmodule Phoenix.PubSub.RedisTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Phoenix.PubSub.Redis

  describe "build_opts/1" do
    test "build opts with defaults" do
      assert Map.new(Redis.build_opts(name: Phoenix.TestName, adapter_name: :adapter_name)) ==
               Map.new(
                 node_name: node(),
                 name: Phoenix.TestName,
                 adapter_name: :adapter_name,
                 redis_pool_size: 5,
                 redis_opts: [],
                 compression_level: 0
               )
    end

    test "fill redis opts as-is" do
      assert Map.new(
               Redis.build_opts(
                 name: Phoenix.TestName,
                 adapter_name: :adapter_name,
                 redis_opts: [
                   host: "example.com",
                   port: 5000,
                   password: "password",
                   database: 1,
                   ssl: true,
                   socket_opts: [verify: :no_verify],
                   sentinel: [
                     sentinels: [
                       "redis://sent1.example.com:26379",
                       "redis://sent2.example.com:26379"
                     ],
                     group: "main"
                   ]
                 ]
               )
             ) ==
               Map.new(
                 node_name: node(),
                 name: Phoenix.TestName,
                 adapter_name: :adapter_name,
                 redis_pool_size: 5,
                 compression_level: 0,
                 redis_opts: [
                   host: "example.com",
                   port: 5000,
                   password: "password",
                   database: 1,
                   ssl: true,
                   socket_opts: [verify: :no_verify],
                   sentinel: [
                     sentinels: [
                       "redis://sent1.example.com:26379",
                       "redis://sent2.example.com:26379"
                     ],
                     group: "main"
                   ]
                 ]
               )
    end

    test "warns when top-level Redis keys are used" do
      warning =
        capture_io(:stderr, fn ->
          Redis.build_opts(name: Phoenix.TestName, adapter_name: :adapter_name, host: "localhost")
        end)

      assert warning =~ "Passing Redis connection keys at the top level is deprecated"
      assert warning =~ ":host"
    end

    test "raises when both top-level keys and redis_opts are provided" do
      assert_raise ArgumentError,
                   "only one of :redis_opts or top-level Redis keys may be provided, not both",
                   fn ->
                     Redis.build_opts(
                       name: Phoenix.TestName,
                       adapter_name: :adapter_name,
                       host: "example.com",
                       redis_opts: [password: "password"]
                     )
                   end
    end

    test "warns and uses only url when url is mixed with other top-level keys" do
      warning =
        capture_io(:stderr, fn ->
          opts =
            Redis.build_opts(
              name: Phoenix.TestName,
              adapter_name: :adapter_name,
              url: "redis://example.com:6379",
              password: "secret"
            )

          assert opts[:redis_opts] == "redis://example.com:6379"
        end)

      assert warning =~ "Passing Redis connection keys at the top level is deprecated"
      assert warning =~ "Passing :url with other top-level Redis keys is not supported"
    end

    test "url string is passed through directly as redis_opts" do
      assert Map.new(
               Redis.build_opts(
                 name: Phoenix.TestName,
                 adapter_name: :adapter_name,
                 redis_opts: "rediss://username:password@example.com:5000/1"
               )
             ) ==
               Map.new(
                 node_name: node(),
                 name: Phoenix.TestName,
                 adapter_name: :adapter_name,
                 redis_pool_size: 5,
                 compression_level: 0,
                 redis_opts: "rediss://username:password@example.com:5000/1"
               )
    end
  end
end
