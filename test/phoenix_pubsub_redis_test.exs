Application.put_env(
  :phoenix_pubsub,
  :test_adapter,
  {Phoenix.PubSub.Redis, node_name: :SAMPLE, compression_level: 1}
)

Code.require_file("#{Mix.Project.deps_paths()[:phoenix_pubsub]}/test/shared/pubsub_test.exs")

defmodule Phoenix.PubSub.RedisTest do
  use ExUnit.Case, async: true

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

    test "redis_opts will be merged redis opts from root" do
      assert Map.new(
               Redis.build_opts(
                 name: Phoenix.TestName,
                 adapter_name: :adapter_name,
                 host: "example.com",
                 port: 5000,
                 password: "another",
                 database: 1,
                 redis_opts: [
                   password: "password",
                   database: 2
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
                   database: 2
                 ]
               )
    end

    test "parse url opts" do
      assert Map.new(
               Redis.build_opts(
                 name: Phoenix.TestName,
                 adapter_name: :adapter_name,
                 url: "rediss://username:password@example.com:5000/1"
               )
             ) ==
               Map.new(
                 node_name: node(),
                 name: Phoenix.TestName,
                 adapter_name: :adapter_name,
                 redis_pool_size: 5,
                 compression_level: 0,
                 redis_opts: [
                   ssl: true,
                   database: 1,
                   password: "password",
                   username: "username",
                   port: 5000,
                   host: "example.com"
                 ]
               )
    end
  end
end
