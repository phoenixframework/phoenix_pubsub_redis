defmodule PhoenixPubsubRedis.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :phoenix_pubsub_redis,
     version: @version,
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps,
     source_url: "https://github.com/phoenixframework/phoenix_pubsub_redis",
     description: """
     The Redis PubSub adapter for the Phoenix framework
     """]
  end

  def application do
    [applications: [:logger, :redo, :poolboy]]
  end

  defp deps do
    # TODO bump phoenix version on next release
    [{:phoenix, github: "phoenixframework/phoenix"},
     {:redo, "~> 2.0.1"},
     {:poolboy, "~> 1.5.1 or ~> 1.6"}]
  end

  defp package do
    [contributors: ["Chris McCord"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/phoenixframework/phoenix_pubsub_redis"}]
  end
end
