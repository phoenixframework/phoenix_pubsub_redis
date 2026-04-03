defmodule Phoenix.PubSub.Redis do
  @moduledoc """
  Phoenix PubSub adapter based on Redis.

  To start it, list it in your supervision tree as:

      {Phoenix.PubSub,
       adapter: Phoenix.PubSub.Redis,
       redis_opts: "redis://localhost:6379",
       node_name: System.get_env("NODE")}

  ## Options

    * `:name` - The required name to register the PubSub processes, e.g. `MyApp.PubSub`.
    * `:node_name` - The name of the node, used to filter out messages broadcast by the same node. Defaults to `node()`. Must be unique.
    * `:redis_pool_size` - The size of the Redis connection pool. Defaults to `5`.
    * `:compression_level` - Compression level applied to serialized terms - `0` (none) to `9` (highest). Defaults to `0`.
    * `:redis_opts` - Redix connection options - either a Redis URL string or a keyword list. See `Redix.start_link/1` for more information.

  """

  use Supervisor

  @behaviour Phoenix.PubSub.Adapter

  @schema NimbleOptions.new!(
            node_name: [
              type: {:or, [:atom, :string]},
              doc: "The name of the node. Defaults to `node()`. Must be unique."
            ],
            redis_pool_size: [
              type: :pos_integer,
              default: 5,
              doc: "The size of the Redis connection pool."
            ],
            compression_level: [
              type: {:in, 0..9},
              default: 0,
              doc: "Compression level applied to serialized terms - `0` (none) to `9` (highest)."
            ],
            redis_opts: [
              type: {:or, [:string, :keyword_list]},
              default: [],
              doc:
                "Redix connection options - either a Redis URL string or a keyword list. " <>
                  "See `Redix.start_link/1` for more information."
            ]
          )

  # Using top-level configuration keys for Redis configuration is deprecated
  @redis_top_level_keys [
    :host,
    :port,
    :username,
    :password,
    :database,
    :ssl,
    :socket_opts,
    :sentinel,
    :url
  ]

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
    {internal, user_opts} =
      Keyword.split(opts, [:name, :adapter_name, :adapter, :pool_size, :registry_size])

    {top_level_redis, user_opts} = Keyword.split(user_opts, @redis_top_level_keys)

    validated =
      user_opts
      |> Keyword.put_new(:node_name, node())
      |> NimbleOptions.validate!(@schema)

    redis_opts = build_redis_opts(top_level_redis, validated[:redis_opts])

    internal
    |> Keyword.put(:node_name, validated[:node_name])
    |> Keyword.put(:compression_level, validated[:compression_level])
    |> Keyword.put(:redis_pool_size, validated[:redis_pool_size])
    |> Keyword.put(:redis_opts, redis_opts)
  end

  defp build_redis_opts(top_level, redis_opts) do
    case {top_level, redis_opts} do
      # no options provided, use defaults
      {[], []} ->
        []

      {[_ | _], []} ->
        keys = top_level |> Keyword.keys() |> Enum.map_join(", ", &inspect/1)

        IO.warn(
          "Passing Redis connection keys at the top level is deprecated. " <>
            "Move #{keys} inside the :redis_opts option instead.",
          []
        )

        case Keyword.pop(top_level, :url) do
          {nil, opts} ->
            opts

          {url, []} ->
            url

          {url, _other} ->
            IO.warn(
              "Passing :url with other top-level Redis keys is not supported. " <>
                "Only the :url value will be used. Use redis_opts: \"#{url}\" instead.",
              []
            )

            url
        end

      {[], redis_opts} when redis_opts != [] ->
        redis_opts

      # deprecated and new options both provided
      _multiple ->
        raise ArgumentError,
              "only one of :redis_opts or top-level Redis keys may be provided, not both"
    end
  end

  defp validate_node_name!(node_name) do
    if node_name in [nil, :nonode@nohost] do
      raise ArgumentError, ":node_name is a required option for unnamed nodes"
    end

    :ok
  end
end
