defmodule MCP do
  @moduledoc """
  The official Elixir SDK for Model Context Protocol (MCP) servers and clients.

  ## Overview

  The Model Context Protocol (MCP) is an open protocol that standardizes how applications
  provide context to Large Language Models (LLMs). This SDK provides idiomatic Elixir
  abstractions for building MCP servers that expose tools, resources, and prompts.

  ## Quick Start

  Define an MCP server by using the `MCP.Server` behavior:

      defmodule MyApp.MCPServer do
        use MCP.Server

        def init(_opts) do
          {:ok, %{}}
        end

        def handle_init(state) do
          server = self()

          # Register a tool
          MCP.Server.register_tool(
            server,
            "add",
            "Adds two numbers",
            %{a: :number, b: :number},
            fn %{a: a, b: b} -> a + b end
          )

          # Register a resource
          MCP.Server.register_resource(
            server,
            "config://version",
            "Version",
            "Application version",
            "text/plain",
            fn _params -> "1.0.0" end
          )

          # Register a prompt
          MCP.Server.register_prompt(
            server,
            "explain",
            "Generates an explanation prompt",
            [%{name: "topic", description: "Topic to explain", required: true}],
            fn %{topic: topic} -> "Explain \#{topic} in simple terms" end
          )

          {:ok, state}
        end
      end

  Start the server with stdio transport:

      # Start the server
      {:ok, server_pid} = MyApp.MCPServer.start_link(name: "my-server", version: "1.0.0")

      # Start stdio transport
      {:ok, _transport_pid} = MCP.Transport.Stdio.start_link(server: server_pid)

  ## Features

  - **Protocol Compliance**: Full JSON-RPC 2.0 implementation
  - **Type Safety**: Schema validation for tools, resources, and prompts
  - **Multiple Transports**: stdio (local), HTTP/SSE (remote)
  - **Idiomatic Elixir**: GenServer-based architecture with supervision support
  - **Easy Registration**: Simple API for registering capabilities

  ## Core Modules

  - `MCP.Server` - Main server behavior and implementation
  - `MCP.Schema` - Schema definition and validation
  - `MCP.Capabilities.Tool` - Tool capability
  - `MCP.Capabilities.Resource` - Resource capability
  - `MCP.Capabilities.Prompt` - Prompt capability
  - `MCP.Transport.Stdio` - Standard I/O transport
  - `MCP.Transport.HTTP` - HTTP/SSE transport
  - `MCP.Protocol.Message` - JSON-RPC message handling

  ## Transport Options

  ### Stdio (Local)

  Use for desktop applications and local integrations:

      MCP.Transport.Stdio.start_link(server: server_pid)

  ### HTTP (Remote)

  Use for web-based and remote deployments:

      # In your Phoenix controller or Plug
      def mcp_endpoint(conn, _params) do
        MCP.Transport.HTTP.handle_request(conn, MyApp.MCPServer)
      end

  ## Protocol Version

  This SDK implements MCP protocol version: `2024-11-05`

  ## Links

  - [MCP Specification](https://modelcontextprotocol.io)
  - [Source Code](https://gitlab.com/pranavraja/elixir-sdk)
  """

  @version Mix.Project.config()[:version]

  @doc """
  Returns the SDK version.
  """
  def version, do: @version

  @doc """
  Returns the supported MCP protocol version.
  """
  def protocol_version, do: "2024-11-05"
end
