defmodule PhoenixPubsubRedis.Mixfile do
  use Mix.Project

  @version "2.1.4"

  def project do
    [app: :phoenix_pubsub_redis,
     version: @version,
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package(),
     deps: deps(),
     source_url: "https://github.com/phoenixframework/phoenix_pubsub_redis",
     description: """
     The Redis PubSub adapter for the Phoenix framework
     """]
  end

  def application do
    [applications: [:logger, :poolboy, :redix, :phoenix_pubsub]]
  end

  defp deps do
    [{:phoenix_pubsub, "~> 1.0"},
     {:redix, "~> 0.9.0"},
     {:ex_doc, "~> 0.19.0", only: :docs},
     {:poolboy, "~> 1.5.1 or ~> 1.6"}]
  end

  defp package do
    [maintainers: ["Chris McCord"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/phoenixframework/phoenix_pubsub_redis"}]
  end
end
