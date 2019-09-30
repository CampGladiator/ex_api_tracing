defmodule CgExRay.MixProject do
  use Mix.Project

  def project do
    [
      app: :cg_ex_ray,
      version: "0.0.1",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Wrapper around ex_ray for OpenTrace in Elixir Phoenix",
      package: package(),
      aliases: aliases(),
      name: "CgExRay",
      source_url: "https://github.com/CampGladiator/cg_ex_ray"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [# These are the default files included in the package
     files: ["lib", "mix.exs", "README*"],
     maintainers: ["vivek.s@campgladiator.com"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/CampGladiator/cg_ex_ray"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:ex_ray , "~> 0.1"},
      {:plug, "~> 1.7"},
      {:pre_plug, "~> 1.0"},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      lint: [
        "credo suggest --ignore-checks moduledoc,aliasusage,maxlinelength,aliasorder --strict"
      ]
    ]
  end
end
