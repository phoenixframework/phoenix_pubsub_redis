## Phoenix.PubSub.Redis

> A Redis PubSub adapter for the Phoenix framework

See the [docs](https://hexdocs.pm/phoenix_pubsub_redis/) for more information.

## Usage

To use Redis as your PubSub adapter, simply add it to your deps and Application's Supervisor tree:

```elixir
# mix.exs
defp deps do
  [{:phoenix_pubsub_redis, "~> 3.0.0"}],
end

# application.ex
children = [
  # ...,
  {Phoenix.PubSub,
   adapter: Phoenix.PubSub.Redis,
   host: "192.168.1.100",
   node_name: System.get_env("NODE")}
```

Config Options

Option                  | Description                                                               | Default        |
:-----------------------| :------------------------------------------------------------------------ | :------------- |
`:name`                 | The required name to register the PubSub processes, ie: `MyApp.PubSub`    |                |
`:node_name`            | The required and unique name of the node, ie: `System.get_env("NODE")`    |                |
`:url`                  | The redis-server URL, ie: `redis://username:password@host:port`           |                |
`:host`                 | The redis-server host IP                                                  | `"127.0.0.1"`  |
`:port`                 | The redis-server port                                                     | `6379`         |
`:password`             | The redis-server password                                                 | `""`           |
`:compression_level`    | Compression level applied to serialized terms (`0` - none, `9` - highest) | `0`            |
`:socket_opts`          | The redis-server network layer options                                    | `[]`           |

And also add `:phoenix_pubsub_redis` to your list of applications:

```elixir
# mix.exs
def application do
  [mod: {MyApp, []},
   applications: [..., :phoenix, :phoenix_pubsub_redis]]
end
```