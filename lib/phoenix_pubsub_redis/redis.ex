defmodule Phoenix.PubSub.Redis do
  use Supervisor

  @moduledoc """
  Phoenix PubSub adapter based on Redis.

  To use Redis as your PubSub adapter, simply add it to your Endpoint's config:

      config :my_app, MyApp.Endpiont,
        pubsub: [adapter: Phoenix.PubSub.Redis,
                 host: "192.168.1.100"]

  You will also need to add `:phoenix_pubsub_redis` to your deps:

      defp deps do
        [{:phoenix_pubsub_redis, "~> 0.1.0"}]
      end

  And also add `:phoenix_pubsub_redis` to your list of applications:

      def application do
        [mod: {MyApp, []},
         applications: [..., :phoenix, :phoenix_pubsub_redis]]
      end

  ## Options

    * `:url` - The url to the redis server ie: `redis://username:password@host:port`
    * `:name` - The required name to register the PubSub processes, ie: `MyApp.PubSub`
    * `:host` - The redis-server host IP, defaults `"127.0.0.1"`
    * `:port` - The redis-server port, defaults `6379`
    * `:password` - The redis-server password, defaults `""`

  """

  @pool_size 5
  @defaults [host: "127.0.0.1", port: 6379]


  def start_link(name, opts) do
    supervisor_name = Module.concat(name, Supervisor)
    Supervisor.start_link(__MODULE__, [name, opts], name: supervisor_name)
  end

  @doc false
  def init([server_name, opts]) do
    if opts[:url] do
      info = URI.parse(opts[:url])
      destructure [username, password], String.split(info.userinfo, ":")
      opts = Keyword.merge(opts, password: password, username: username, host: info.host, port: info.port)
    end

    opts = Keyword.merge(@defaults, opts)
    opts = Keyword.merge(opts, host: String.to_char_list(opts[:host]))
    if pass = opts[:password] do
      opts = Keyword.put(opts, :pass, String.to_char_list(pass))
    end

    pool_name   = Module.concat(server_name, Pool)
    local_name  = Module.concat(server_name, Local)
    namespace   = redis_namespace(server_name)
    node_ref    = :crypto.strong_rand_bytes(24)
    server_opts = Keyword.merge(opts, name: server_name,
                                      local_name: local_name,
                                      pool_name: pool_name,
                                      namespace: namespace,
                                      node_ref: node_ref)
    pool_opts = [
      name: {:local, pool_name},
      worker_module: Phoenix.PubSub.RedisConn,
      size: opts[:pool_size] || @pool_size,
      max_overflow: 0
    ]

    # Define a dispatch table so we don't have to go through
    # a bottleneck to get the instruction to perform.
    :ets.new(server_name, [:set, :named_table, read_concurrency: true])
    true = :ets.insert(server_name, {:broadcast, Phoenix.PubSub.RedisServer,
                                    [pool_name, namespace, node_ref]})
    true = :ets.insert(server_name, {:subscribe, Phoenix.PubSub.Local, [local_name]})
    true = :ets.insert(server_name, {:unsubscribe, Phoenix.PubSub.Local, [local_name]})

    children = [
      worker(Phoenix.PubSub.Local, [local_name]),
      :poolboy.child_spec(pool_name, pool_opts, [opts]),
      worker(Phoenix.PubSub.RedisServer, [server_opts]),
    ]
    supervise children, strategy: :one_for_all
  end

  defp redis_namespace(server_name), do: "phx:#{server_name}"
end
