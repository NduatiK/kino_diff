defmodule KinoDiff.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :kino_diff,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:kino, "~> 0.9"},
      {:diffy, "~> 1.1"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Library for displaying string diffs in Livebook.
    """
  end

  defp docs() do
    # The main page in the docs
    [
      main: "KinoDiff",
      extras: ["example.livemd"],
      source_url: "https://github.com/NduatiK/kino_diff",
      source_ref: "#{@version}"
    ]
  end

  defp package do
    [
      # files: ["lib", "mix.exs", "README*", "LICENSE*", "screenshots/*"],
      maintainers: ["Nduati Kuria"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/NduatiK/kino_diff"}
    ]
  end
end
