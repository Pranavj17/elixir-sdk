defmodule MCP.Transport.HTTP do
  @moduledoc """
  HTTP/SSE transport for MCP servers.

  Provides streamable HTTP transport for remote MCP servers.
  This transport is suitable for web-based and remote deployments.

  Note: Requires the `plug` dependency to be available.
  """

  @doc """
  Handles an HTTP request for MCP communication.

  ## Parameters
  - `conn` - Plug connection
  - `server` - MCP server module or PID

  ## Returns
  Updated Plug connection with response
  """
  def handle_request(conn, server) do
    if Code.ensure_loaded?(Plug.Conn) do
      do_handle_request(conn, server)
    else
      raise "Plug is required for HTTP transport. Add {:plug, \"~> 1.16\"} to your dependencies."
    end
  end

  defp do_handle_request(conn, server) do
    # Read request body
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    # Parse JSON-RPC message
    case Jason.decode(body) do
      {:ok, message} ->
        # Process message through server
        response = process_message(server, message)

        # Send response
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response))

      {:error, _} ->
        error = %{
          jsonrpc: "2.0",
          error: %{
            code: -32700,
            message: "Parse error"
          },
          id: nil
        }

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(400, Jason.encode!(error))
    end
  end

  @doc """
  Handles Server-Sent Events (SSE) streaming.

  Note: This is a placeholder for future SSE support.
  """
  def handle_sse(_conn, _server) do
    raise "SSE transport is not yet implemented"
  end

  # Private functions

  defp process_message(server, message) when is_pid(server) do
    # Send message to server process and wait for response
    send(server, {:mcp_message, message})

    receive do
      {:mcp_response, response} -> response
    after
      5000 -> timeout_error(message)
    end
  end

  defp process_message(server, message) when is_atom(server) do
    # Call server module directly
    server.handle_message(message)
  end

  defp timeout_error(message) do
    %{
      jsonrpc: "2.0",
      error: %{
        code: -32603,
        message: "Internal error: timeout"
      },
      id: Map.get(message, "id")
    }
  end
end
