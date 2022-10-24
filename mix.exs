defmodule ElixirAuthFacebook.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_auth_facebook,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
      description: "Turnkey Facebook OAuth for Elixir/Phoenix App.",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        c: :test,
        coveralls: :test,
        "coveralls.json": :test,
        "coveralls.html": :test,
        t: :test
      ]
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
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:httpoison, "~> 1.8"},
      {:ex_doc, "~> 0.29.0", only: :dev},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:sobelow, "~> 0.8", only: :dev}
    ]
  end

  defp aliases do
    [
      t: ["test"],
      c: ["coveralls.html"]
    ]
  end

  defp package() do
    [
      files: ~w(lib/elixir_auth_facebook.ex lib/httpoison_mock.ex LICENSE mix.exs README.md),
      name: "elixir_auth_facebook",
      licenses: ["GPL-2.0-or-later"],
      maintainers: ["dwyl"],
      links: %{"GitHub" => "https://github.com/dwyl/elixir-auth-facebook"}
    ]
  end
end
