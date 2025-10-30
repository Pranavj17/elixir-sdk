defmodule MCP.Capabilities.Tool do
  @moduledoc """
  Tool capability for MCP servers.

  Tools are functions that the AI can execute. They receive arguments
  and return results in a structured format.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          input_schema: map(),
          handler: function()
        }

  defstruct [:name, :description, :input_schema, :handler]

  @doc """
  Creates a new tool definition.

  ## Parameters
  - `name` - Tool name (must be unique)
  - `description` - Human-readable description
  - `input_schema` - JSON Schema for tool arguments
  - `handler` - Function that executes the tool (arity 1, receives arguments map)

  ## Examples

      tool = Tool.new(
        "add",
        "Adds two numbers",
        %{a: :number, b: :number},
        fn %{a: a, b: b} -> a + b end
      )
  """
  def new(name, description, input_schema, handler)
      when is_binary(name) and is_binary(description) and is_function(handler, 1) do
    %__MODULE__{
      name: name,
      description: description,
      input_schema: MCP.Schema.to_json_schema(input_schema),
      handler: handler
    }
  end

  @doc """
  Converts a tool to the MCP tools/list response format.
  """
  def to_list_format(%__MODULE__{} = tool) do
    %{
      name: tool.name,
      description: tool.description,
      inputSchema: tool.input_schema
    }
  end

  @doc """
  Executes a tool with the given arguments.

  Returns `{:ok, result}` or `{:error, reason}`.
  """
  def execute(%__MODULE__{} = tool, arguments) do
    with {:ok, validated_args} <- validate_arguments(tool, arguments),
         {:ok, result} <- call_handler(tool.handler, validated_args) do
      {:ok, format_result(result)}
    end
  rescue
    error ->
      {:error, %{message: Exception.message(error), type: error.__struct__}}
  end

  # Private functions

  defp validate_arguments(tool, arguments) when is_map(arguments) do
    MCP.Schema.validate(arguments, tool.input_schema)
  end

  defp validate_arguments(_tool, _arguments) do
    {:error, :invalid_arguments}
  end

  defp call_handler(handler, arguments) do
    try do
      result = handler.(arguments)
      {:ok, result}
    rescue
      error -> {:error, Exception.message(error)}
    end
  end

  defp format_result(result) when is_binary(result) do
    %{
      content: [
        %{
          type: "text",
          text: result
        }
      ]
    }
  end

  defp format_result(result) when is_map(result) do
    # If result already has the MCP format, return as-is
    if Map.has_key?(result, :content) or Map.has_key?(result, "content") do
      result
    else
      # Otherwise, create structured content
      %{
        content: [
          %{
            type: "text",
            text: Jason.encode!(result)
          }
        ],
        structuredContent: result
      }
    end
  end

  defp format_result(result) when is_list(result) do
    %{
      content: [
        %{
          type: "text",
          text: Jason.encode!(result)
        }
      ],
      structuredContent: result
    }
  end

  defp format_result(result) do
    %{
      content: [
        %{
          type: "text",
          text: inspect(result)
        }
      ]
    }
  end
end
