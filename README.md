## Phoenix.PubSub.Redis

> A Redis PubSub adapter for the Phoenix framework

See the [docs](https://hexdocs.pm/phoenix_pubsub_redis/) for more information.

## Usage

To use Redis as your PubSub adapter, simply add it to your deps and Application's Supervisor tree:

```elixir
# mix.exs
defp deps do
  [{:phoenix_pubsub_redis, "~> 3.0"}],
end

# application.ex
children = [
  # ...,
  {Phoenix.PubSub,
   adapter: Phoenix.PubSub.Redis,
   redis_opts: [host: "192.168.1.100"],
   node_name: System.get_env("NODE")}
```

Config Options

Option                  | Description                                                                                | Default        |
:-----------------------| :----------------------------------------------------------------------------------------- | :------------- |
`:name`                 | The required name to register the PubSub processes, ie: `MyApp.PubSub`                     |                |
`:node_name`            | The required and unique name of the node, ie: `System.get_env("NODE")`                     |                |
`:url`                  | The redis-server URL, ie: `redis://username:password@host:port`                            |                |
`:compression_level`    | Compression level applied to serialized terms (`0` - none, `9` - highest)                  | `0`            |
`:redis_pool_size`      | The size of the redis connection pool.                                                     | `5`            |
`:redis_opts`           | Redis connection opts. See: https://hexdocs.pm/redix/Redix.html#start_link/1-redis-options |                |
