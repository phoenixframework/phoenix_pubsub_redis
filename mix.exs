defmodule PhoenixPubsubRedis.Mixfile do
  use Mix.Project

  @version "3.0.1"
  @source_url "https://github.com/phoenixframework/phoenix_pubsub_redis"

  def project do
    [
      app: :phoenix_pubsub_redis,
      version: @version,
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      description: "The Redis PubSub adapter for the Phoenix framework",
      docs: [
        source_ref: "v#{@version}",
        source_url: @source_url,
        main: "Phoenix.PubSub.Redis"
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      phoenix_pubsub(),
      {:redix, "~> 0.10.0 or ~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :docs},
      {:poolboy, "~> 1.5.1 or ~> 1.6"}
    ]
  end

  defp phoenix_pubsub do
    if path = System.get_env("PUBSUB_PATH") do
      {:phoenix_pubsub, "~> 2.0", path: path}
    else
      {:phoenix_pubsub, "~> 2.0"}
    end
  end

  defp package do
    [
      maintainers: ["Chris McCord"],
      licenses: ["MIT"],
      links: %{GitHub: @source_url}
    ]
  end
end
