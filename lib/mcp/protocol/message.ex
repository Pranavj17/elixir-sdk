defmodule MCP.Protocol.Message do
  @moduledoc """
  JSON-RPC 2.0 message structures for Model Context Protocol.

  Defines request, response, notification, and error message formats
  according to the JSON-RPC 2.0 specification.
  """

  @type id :: String.t() | integer() | nil
  @type method :: String.t()
  @type params :: map() | list() | nil

  @doc """
  Creates a JSON-RPC request message.
  """
  def request(id, method, params \\ nil) do
    %{
      jsonrpc: "2.0",
      id: id,
      method: method,
      params: params
    }
    |> compact()
  end

  @doc """
  Creates a JSON-RPC notification message (no response expected).
  """
  def notification(method, params \\ nil) do
    %{
      jsonrpc: "2.0",
      method: method,
      params: params
    }
    |> compact()
  end

  @doc """
  Creates a JSON-RPC success response.
  """
  def response(id, result) do
    %{
      jsonrpc: "2.0",
      id: id,
      result: result
    }
  end

  @doc """
  Creates a JSON-RPC error response.
  """
  def error_response(id, code, message, data \\ nil) do
    error = %{
      code: code,
      message: message
    }

    error =
      if data do
        Map.put(error, :data, data)
      else
        error
      end

    %{
      jsonrpc: "2.0",
      id: id,
      error: error
    }
  end

  @doc """
  Standard JSON-RPC error codes.
  """
  def error_code(:parse_error), do: -32700
  def error_code(:invalid_request), do: -32600
  def error_code(:method_not_found), do: -32601
  def error_code(:invalid_params), do: -32602
  def error_code(:internal_error), do: -32603

  @doc """
  Validates a JSON-RPC message.
  """
  def validate(msg) when is_map(msg) do
    with :ok <- validate_jsonrpc(msg),
         :ok <- validate_message_type(msg) do
      {:ok, msg}
    end
  end

  def validate(_), do: {:error, :invalid_message}

  defp validate_jsonrpc(%{"jsonrpc" => "2.0"}), do: :ok
  defp validate_jsonrpc(_), do: {:error, :invalid_jsonrpc_version}

  defp validate_message_type(%{"method" => method}) when is_binary(method), do: :ok
  defp validate_message_type(%{"result" => _}), do: :ok
  defp validate_message_type(%{"error" => _}), do: :ok
  defp validate_message_type(_), do: {:error, :invalid_message_type}

  # Remove nil values from map
  defp compact(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
