defmodule MCP.Capabilities.Prompt do
  @moduledoc """
  Prompt capability for MCP servers.

  Prompts are reusable templates that generate messages for the AI.
  They can accept arguments to customize the prompt content.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t() | nil,
          arguments: list(argument()),
          handler: function()
        }

  @type argument :: %{
          name: String.t(),
          description: String.t() | nil,
          required: boolean()
        }

  defstruct [:name, :description, :arguments, :handler]

  @doc """
  Creates a new prompt definition.

  ## Parameters
  - `name` - Prompt name (must be unique)
  - `description` - Human-readable description (optional)
  - `arguments` - List of argument definitions
  - `handler` - Function that generates prompt messages (arity 1, receives arguments map)

  ## Examples

      prompt = Prompt.new(
        "explain",
        "Generates an explanation prompt",
        [
          %{name: "topic", description: "Topic to explain", required: true}
        ],
        fn %{topic: t} ->
          "Explain \#{t} in simple terms"
        end
      )
  """
  def new(name, description \\ nil, arguments \\ [], handler)
      when is_binary(name) and is_list(arguments) and is_function(handler, 1) do
    %__MODULE__{
      name: name,
      description: description,
      arguments: arguments,
      handler: handler
    }
  end

  @doc """
  Converts a prompt to the MCP prompts/list response format.
  """
  def to_list_format(%__MODULE__{} = prompt) do
    base = %{
      name: prompt.name,
      arguments: prompt.arguments || []
    }

    if prompt.description do
      Map.put(base, :description, prompt.description)
    else
      base
    end
  end

  @doc """
  Executes a prompt with the given arguments.

  Returns `{:ok, result}` or `{:error, reason}`.
  """
  def execute(%__MODULE__{} = prompt, arguments) do
    with {:ok, validated_args} <- validate_arguments(prompt, arguments),
         {:ok, result} <- call_handler(prompt.handler, validated_args) do
      {:ok, format_result(result, prompt.description)}
    end
  rescue
    error ->
      {:error, %{message: Exception.message(error), type: error.__struct__}}
  end

  # Private functions

  defp validate_arguments(prompt, arguments) when is_map(arguments) do
    required_args =
      prompt.arguments
      |> Enum.filter(& &1[:required])
      |> Enum.map(& &1[:name])

    missing =
      Enum.filter(required_args, fn arg_name ->
        not Map.has_key?(arguments, arg_name) and
          not Map.has_key?(arguments, String.to_atom(arg_name))
      end)

    if Enum.empty?(missing) do
      {:ok, arguments}
    else
      {:error, {:missing_required_arguments, missing}}
    end
  end

  defp validate_arguments(_prompt, _arguments) do
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

  defp format_result(result, description) when is_binary(result) do
    %{
      description: description || "Generated prompt",
      messages: [
        %{
          role: "user",
          content: %{
            type: "text",
            text: result
          }
        }
      ]
    }
  end

  defp format_result(result, _description) when is_map(result) do
    # If result already has the MCP format, return as-is
    if Map.has_key?(result, :messages) or Map.has_key?(result, "messages") do
      result
    else
      # Otherwise, treat as a single message
      format_result(Jason.encode!(result), nil)
    end
  end

  defp format_result(result, description) when is_list(result) do
    # Assume it's a list of messages
    %{
      description: description || "Generated prompt",
      messages: result
    }
  end

  defp format_result(result, description) do
    format_result(inspect(result), description)
  end
end
