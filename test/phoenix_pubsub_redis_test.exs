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
                 database: "database",
                 ssl: true,
                 socket_opts: [verify: :no_verify],
                 sentinel: [
                   sentinels: [
                     "redis://sent1.example.com:26379",
                     "redis://sent2.example.com:26379"
                   ],
                   group: "main"
                 ],
                 url: "redis://localhost:6379/3"
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
                   database: "database",
                   ssl: true,
                   socket_opts: [verify: :no_verify],
                   sentinel: [
                     sentinels: [
                       "redis://sent1.example.com:26379",
                       "redis://sent2.example.com:26379"
                     ],
                     group: "main"
                   ],
                   url: "redis://localhost:6379/3"
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
                 database: "another",
                 redis_opts: [
                   password: "password",
                   database: "database"
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
                   database: "database"
                 ]
               )
    end
  end
end
