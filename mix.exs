defmodule MCP.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/Pranavj17/elixir-sdk"

  def project do
    [
      app: :mcp_sdk,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "MCP SDK",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:nimble_options, "~> 1.1"},
      {:plug, "~> 1.16", optional: true},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    The official Elixir SDK for Model Context Protocol (MCP) servers and clients.
    Build MCP servers that expose tools, resources, and prompts using idiomatic Elixir patterns.
    """
  end

  defp package do
    [
      name: "mcp_sdk",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "MCP Specification" => "https://modelcontextprotocol.io"
      }
    ]
  end

  defp docs do
    [
      main: "MCP",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
