defmodule Bench.MixProject do
  use Mix.Project

  def project do
    [
      app: :bench,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: false,
      deps: deps(),
      aliases: [setup: ["deps.get", "cmd --cd browser npm install"]]
    ]
  end

  def application do
    [extra_applications: [:logger, :inets]]
  end

  # Fude comes from Hex by default. FUDE_PATH points at a checkout instead,
  # to measure unreleased work; build its bundle there first
  # (`MIX_ENV=dev mix fude.build`), since priv/static is not committed.
  defp fude do
    case System.get_env("FUDE_PATH") do
      nil -> {:fude, "~> 0.8"}
      path -> {:fude, path: path, override: true}
    end
  end

  defp deps do
    [
      fude(),
      {:vega_lite, "~> 0.1.11"},
      {:contex, "~> 0.5.0"},
      {:live_charts, "~> 0.5.0"},
      {:phoenix, "~> 1.8"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.1"},
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.4"}
    ]
  end
end
