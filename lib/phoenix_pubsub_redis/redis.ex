defmodule Phoenix.PubSub.Redis do
  @moduledoc """
  Phoenix PubSub adapter based on Redis.

  To start it, list it in your supervision tree as:

      {Phoenix.PubSub,
       adapter: Phoenix.PubSub.Redis,
       host: "192.168.1.100",
       node_name: System.get_env("NODE")}

  You will also need to add `:phoenix_pubsub_redis` to your deps:

      defp deps do
        [{:phoenix_pubsub_redis, "~> 2.1.0"}]
      end

  ## Options

    * `:url` - The url to the redis server ie: `redis://username:password@host:port`
    * `:name` - The required name to register the PubSub processes, ie: `MyApp.PubSub`
    * `:node_name` - The required name of the node, defaults to Erlang --sname flag. It must be unique.
    * `:host` - The redis-server host IP, defaults `"127.0.0.1"`
    * `:port` - The redis-server port, defaults `6379`
    * `:password` - The redis-server password, defaults `""`
    * `:ssl` - The redis-server ssl option, defaults `false`
    * `:redis_pool_size` - The size of the redis connection pool. Defaults `5`
    * `:compression_level` - Compression level applied to serialized terms - from `0` (no compression), to `9` (highest). Defaults `0`
    * `:socket_opts` - List of options that are passed to the network layer when connecting to the Redis server. Default `[]`
    * `:sentinel` - Redix sentinel configuration. Default to `nil`

  """

  use Supervisor

  @behaviour Phoenix.PubSub.Adapter
  @redis_pool_size 5
  @compression_level 0
  @redis_opts [:host, :port, :password, :database, :ssl, :socket_opts, :sentinel]

  ## Adapter callbacks

  @impl true
  defdelegate node_name(adapter_name),
    to: Phoenix.PubSub.RedisServer

  @impl true
  defdelegate broadcast(adapter_name, topic, message, dispatcher),
    to: Phoenix.PubSub.RedisServer

  @impl true
  defdelegate direct_broadcast(adapter_name, node_name, topic, message, dispatcher),
    to: Phoenix.PubSub.RedisServer

  ## GenServer callbacks

  @doc false
  def start_link(opts) do
    adapter_name = Keyword.fetch!(opts, :adapter_name)
    supervisor_name = Module.concat(adapter_name, "Supervisor")
    Supervisor.start_link(__MODULE__, opts, name: supervisor_name)
  end

  @impl true
  def init(opts) do
    opts = build_opts(opts)
    pubsub_name = Keyword.fetch!(opts, :name)
    adapter_name = Keyword.fetch!(opts, :adapter_name)
    compression_level = Keyword.fetch!(opts, :compression_level)
    redis_opts = Keyword.fetch!(opts, :redis_opts)
    node_name = Keyword.fetch!(opts, :node_name)
    redis_pool_size = Keyword.fetch!(opts, :redis_pool_size)

    validate_node_name!(node_name)

    :ets.new(adapter_name, [:public, :named_table, read_concurrency: true])
    :ets.insert(adapter_name, {:node_name, node_name})
    :ets.insert(adapter_name, {:compression_level, compression_level})

    pool_opts = [
      name: {:local, adapter_name},
      worker_module: Redix,
      size: redis_pool_size,
      max_overflow: 0
    ]

    children = [
      {Phoenix.PubSub.RedisServer, {pubsub_name, adapter_name, node_name, redis_opts}},
      :poolboy.child_spec(adapter_name, pool_opts, redis_opts)
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  @doc false
  def build_opts(opts) do
    opts
    |> Keyword.put_new(:redis_pool_size, @redis_pool_size)
    |> Keyword.put_new(:compression_level, @compression_level)
    |> Keyword.put(:redis_opts, redis_opts(opts))
    |> Keyword.put_new(:node_name, node())
    |> Keyword.take([
      :node_name,
      :compression_level,
      :name,
      :adapter_name,
      :redis_opts,
      :redis_pool_size
    ])
  end

  defp redis_opts(opts) do
    # TODO: update docs
    # TODO: parse uri https://github.com/whatyouhide/redix/blob/v1.1.5/lib/redix/uri.ex#L5
    opts
    |> Keyword.take(@redis_opts ++ [:url])
    |> Keyword.merge(Keyword.get(opts, :redis_opts, []))
  end

  defp validate_node_name!(node_name) do
    if node_name in [nil, :nonode@nohost] do
      raise ArgumentError, ":node_name is a required option for unnamed nodes"
    end

    :ok
  end
end
