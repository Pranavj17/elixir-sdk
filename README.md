# Elixir SDK for Model Context Protocol (MCP)

[![Hex.pm](https://img.shields.io/hexpm/v/mcp_sdk.svg)](https://hex.pm/packages/mcp_sdk)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/mcp_sdk)

The official Elixir SDK for building [Model Context Protocol](https://modelcontextprotocol.io) (MCP) servers and clients.

## What is MCP?

The Model Context Protocol (MCP) is an open protocol that standardizes how applications provide context to Large Language Models (LLMs). It enables:

- **Tools**: Functions that LLMs can execute
- **Resources**: Data that LLMs can access
- **Prompts**: Reusable templates for LLM interactions

## Features

- ✅ **Full Protocol Compliance**: Implements MCP specification version `2024-11-05`
- ✅ **JSON-RPC 2.0**: Complete JSON-RPC message handling
- ✅ **Type Safety**: Schema validation for all capabilities
- ✅ **Multiple Transports**: stdio (local) and HTTP/SSE (remote)
- ✅ **Idiomatic Elixir**: GenServer-based with supervision support
- ✅ **Easy Registration**: Simple API for tools, resources, and prompts

## Installation

Add `mcp_sdk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mcp_sdk, "~> 0.1.0"}
  ]
end
```

## Quick Start

### 1. Define an MCP Server

```elixir
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
      fn %{topic: topic} -> "Explain #{topic} in simple terms" end
    )

    {:ok, state}
  end
end
```

### 2. Start the Server

```elixir
# Start the MCP server
{:ok, server_pid} = MyApp.MCPServer.start_link(name: "my-server", version: "1.0.0")

# Start stdio transport (for local/desktop use)
{:ok, _transport_pid} = MCP.Transport.Stdio.start_link(server: server_pid)
```

### 3. Use with Claude Desktop

Add to your Claude Desktop configuration (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "my-server": {
      "command": "/path/to/your/elixir/app"
    }
  }
}
```

## Core Concepts

### Tools

Tools are functions that the AI can execute:

```elixir
MCP.Server.register_tool(
  server,
  "multiply",
  "Multiplies two numbers",
  %{a: :number, b: :number},
  fn %{a: a, b: b} ->
    %{
      result: a * b,
      message: "#{a} × #{b} = #{a * b}"
    }
  end
)
```

### Resources

Resources provide data access with URI-based routing:

```elixir
# Static resource
MCP.Server.register_resource(
  server,
  "config://database",
  "Database Config",
  "Database configuration",
  "application/json",
  fn _params ->
    Jason.encode!(%{host: "localhost", port: 5432})
  end
)

# Dynamic resource with parameters
MCP.Server.register_resource(
  server,
  "user://{user_id}/profile",
  "User Profile",
  "User profile data",
  "application/json",
  fn %{user_id: user_id} ->
    Jason.encode!(%{id: user_id, name: "User #{user_id}"})
  end
)
```

### Prompts

Prompts are reusable templates for LLM interactions:

```elixir
MCP.Server.register_prompt(
  server,
  "code_review",
  "Generates a code review prompt",
  [
    %{name: "language", description: "Programming language", required: true},
    %{name: "code", description: "Code to review", required: true}
  ],
  fn %{language: language, code: code} ->
    """
    Please review this #{language} code:

    ```#{language}
    #{code}
    ```

    Focus on:
    - Code quality
    - Best practices
    - Potential bugs
    """
  end
)
```

## Transports

### Stdio Transport (Local)

For desktop applications and local integrations:

```elixir
MCP.Transport.Stdio.start_link(server: server_pid)
```

### HTTP Transport (Remote)

For web-based deployments with Phoenix or Plug:

```elixir
defmodule MyAppWeb.MCPController do
  use MyAppWeb, :controller

  def mcp_endpoint(conn, _params) do
    MCP.Transport.HTTP.handle_request(conn, MyApp.MCPServer)
  end
end
```

## Schema Definition

The SDK provides a simple schema DSL:

```elixir
# Simple type mapping
%{
  name: :string,
  age: :integer,
  email: :string
}

# Advanced schemas with constraints
%{
  name: MCP.Schema.string(description: "User name", min_length: 1, max_length: 100),
  age: MCP.Schema.integer(description: "User age", minimum: 0, maximum: 150),
  tags: MCP.Schema.array(items: MCP.Schema.string())
}
```

## Examples

### Complete Server Example

See [examples/calculator_server.ex](examples/calculator_server.ex) for a complete working example.

### Integration with Phoenix

See [examples/phoenix_integration.ex](examples/phoenix_integration.ex) for Phoenix integration.

## Architecture

```
lib/mcp/
├── server.ex              # Main server behavior
├── schema.ex              # Schema definition and validation
├── protocol/
│   └── message.ex         # JSON-RPC message handling
├── capabilities/
│   ├── tool.ex            # Tool capability
│   ├── resource.ex        # Resource capability
│   └── prompt.ex          # Prompt capability
└── transport/
    ├── stdio.ex           # Stdio transport
    └── http.ex            # HTTP/SSE transport
```

## Protocol Version

This SDK implements MCP protocol version: **2024-11-05**

## Comparison with Other SDKs

| Feature | Elixir SDK | Python SDK | TypeScript SDK |
|---------|-----------|------------|----------------|
| Protocol Version | 2024-11-05 | 2024-11-05 | 2024-11-05 |
| Tools | ✅ | ✅ | ✅ |
| Resources | ✅ | ✅ | ✅ |
| Prompts | ✅ | ✅ | ✅ |
| Stdio Transport | ✅ | ✅ | ✅ |
| HTTP Transport | ✅ | ✅ | ✅ |
| Type Safety | ✅ Typespecs | ✅ Pydantic | ✅ Zod |
| API Style | Registration | Decorators | Registration |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [MCP Specification](https://modelcontextprotocol.io)
- [Source Code](https://gitlab.com/pranavraja/elixir-sdk)
- [Issue Tracker](https://gitlab.com/pranavraja/elixir-sdk/-/issues)

## Acknowledgments

Built following the [Model Context Protocol specification](https://modelcontextprotocol.io) by Anthropic.
