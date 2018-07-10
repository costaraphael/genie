defmodule Genie.MixProject do
  use Mix.Project

  def project do
    [
      app: :genie,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "An inference engine written 100% in Elixir.",
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      prefered_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp package do
    [
      maintainers: ["Raphael Vidal"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/costaraphael/genie"}
    ]
  end

  def docs do
    [main: "Genie", source_url: "https://github.com/costaraphael/genie"]
  end

  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:credo, "~> 0.9.1", only: [:dev, :test], runtime: false},
      {:benchee, "~> 0.13.1", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test, runtime: false}
    ]
  end
end
