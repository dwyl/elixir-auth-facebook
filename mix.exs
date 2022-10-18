defmodule ElixirAuthFacebook.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_map,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "1.6.14"},
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:httpoison, "~> 1.8"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end
end
