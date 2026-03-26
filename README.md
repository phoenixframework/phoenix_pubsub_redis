## Phoenix.PubSub.Redis

> A Redis PubSub adapter for the Phoenix framework

See the [docs](https://hexdocs.pm/phoenix_pubsub_redis/) for more information.

## Usage

To use Redis as your PubSub adapter, simply add it to your deps and application supervision tree:

```elixir
# mix.exs
defp deps do
  [
    {:phoenix_pubsub_redis, "~> 3.0"}
  ]
end

# application.ex
children = [
  # ...,
  {Phoenix.PubSub,
   adapter: Phoenix.PubSub.Redis,
   redis_opts: "redis://localhost:6379",
   node_name: System.get_env("NODE")}

  # or with keyword options:
  {Phoenix.PubSub,
   adapter: Phoenix.PubSub.Redis,
   redis_opts: [host: "example.com", port: 6379],
   node_name: System.get_env("NODE")}
```

Config Options

Option                  | Description                                                                                | Default        |
:-----------------------| :----------------------------------------------------------------------------------------- | :------------- |
`:name`                 | The required name to register the PubSub processes, e.g. `MyApp.PubSub`.                   |                |
`:node_name`            | The name of the node. Must be unique.                                                      | `node()`       |
`:compression_level`    | Compression level applied to serialized terms - `0` (none) to `9` (highest).               | `0`            |
`:redis_pool_size`      | The size of the Redis connection pool.                                                     | `5`            |
`:redis_opts`           | Redix connection options - either a Redis URL string or a keyword list. See [Redix docs](https://hexdocs.pm/redix/Redix.html#start_link/1-redis-options) for details. |                |
