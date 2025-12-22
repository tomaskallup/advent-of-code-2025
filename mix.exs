defmodule AdventOfCode2025.MixProject do
  use Mix.Project

  def project do
    [
      app: :advent_of_code_2025,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      consolidate_protocols: false
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      consolidate_protocols: false
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:memoize, "~> 1.4"},
    ]
  end
end
