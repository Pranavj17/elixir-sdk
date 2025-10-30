defmodule MCP.Schema do
  @moduledoc """
  Schema definition and validation utilities for MCP tools, resources, and prompts.

  Provides a simple DSL for defining input/output schemas compatible with JSON Schema.
  """

  @type schema_type :: :string | :integer | :float | :boolean | :object | :array
  @type schema :: %{
          required(:type) => schema_type(),
          optional(any()) => any()
        }

  @doc """
  Defines a string field.

  ## Options
  - `:required` - Whether the field is required (default: true)
  - `:description` - Field description
  - `:min_length` - Minimum string length
  - `:max_length` - Maximum string length
  - `:pattern` - Regex pattern
  """
  def string(opts \\ []) do
    base = %{type: "string"}
    add_constraints(base, opts)
  end

  @doc """
  Defines an integer field.

  ## Options
  - `:required` - Whether the field is required (default: true)
  - `:description` - Field description
  - `:minimum` - Minimum value
  - `:maximum` - Maximum value
  """
  def integer(opts \\ []) do
    base = %{type: "integer"}
    add_constraints(base, opts)
  end

  @doc """
  Defines a number (float) field.

  ## Options
  - `:required` - Whether the field is required (default: true)
  - `:description` - Field description
  - `:minimum` - Minimum value
  - `:maximum` - Maximum value
  """
  def number(opts \\ []) do
    base = %{type: "number"}
    add_constraints(base, opts)
  end

  @doc """
  Defines a boolean field.

  ## Options
  - `:required` - Whether the field is required (default: true)
  - `:description` - Field description
  """
  def boolean(opts \\ []) do
    base = %{type: "boolean"}
    add_constraints(base, opts)
  end

  @doc """
  Defines an object field with properties.

  ## Options
  - `:required` - Whether the field is required (default: true)
  - `:description` - Field description
  - `:properties` - Map of property schemas
  - `:required_fields` - List of required property names
  """
  def object(opts \\ []) do
    base = %{type: "object"}
    add_constraints(base, opts)
  end

  @doc """
  Defines an array field.

  ## Options
  - `:required` - Whether the field is required (default: true)
  - `:description` - Field description
  - `:items` - Schema for array items
  - `:min_items` - Minimum array length
  - `:max_items` - Maximum array length
  """
  def array(opts \\ []) do
    base = %{type: "array"}
    add_constraints(base, opts)
  end

  @doc """
  Converts a simple type map to JSON Schema format.

  ## Examples

      iex> MCP.Schema.to_json_schema(%{name: :string, age: :integer})
      %{
        type: "object",
        properties: %{
          name: %{type: "string"},
          age: %{type: "integer"}
        },
        required: ["name", "age"]
      }
  """
  def to_json_schema(schema) when is_map(schema) do
    properties =
      schema
      |> Enum.map(fn {key, type} ->
        {to_string(key), type_to_schema(type)}
      end)
      |> Map.new()

    required = Map.keys(schema) |> Enum.map(&to_string/1)

    %{
      type: "object",
      properties: properties,
      required: required
    }
  end

  @doc """
  Validates data against a schema.
  """
  def validate(data, schema) do
    # Basic validation - can be enhanced with more sophisticated validation
    case do_validate(data, schema) do
      :ok -> {:ok, data}
      {:error, _} = error -> error
    end
  end

  # Private functions

  defp type_to_schema(type) when is_atom(type) do
    case type do
      :string -> %{type: "string"}
      :integer -> %{type: "integer"}
      :float -> %{type: "number"}
      :number -> %{type: "number"}
      :boolean -> %{type: "boolean"}
      :object -> %{type: "object"}
      :array -> %{type: "array"}
      _ -> %{type: "string"}
    end
  end

  defp type_to_schema(schema) when is_map(schema), do: schema

  defp add_constraints(base, opts) do
    Enum.reduce(opts, base, fn {key, value}, acc ->
      case key do
        :description -> Map.put(acc, :description, value)
        :min_length -> Map.put(acc, :minLength, value)
        :max_length -> Map.put(acc, :maxLength, value)
        :pattern -> Map.put(acc, :pattern, value)
        :minimum -> Map.put(acc, :minimum, value)
        :maximum -> Map.put(acc, :maximum, value)
        :properties -> Map.put(acc, :properties, value)
        :required_fields -> Map.put(acc, :required, value)
        :items -> Map.put(acc, :items, value)
        :min_items -> Map.put(acc, :minItems, value)
        :max_items -> Map.put(acc, :maxItems, value)
        _ -> acc
      end
    end)
  end

  defp do_validate(data, %{type: "object", properties: props, required: required}) do
    with :ok <- validate_required_fields(data, required),
         :ok <- validate_properties(data, props) do
      :ok
    end
  end

  defp do_validate(data, %{type: "string"}) when is_binary(data), do: :ok
  defp do_validate(data, %{type: "integer"}) when is_integer(data), do: :ok
  defp do_validate(data, %{type: "number"}) when is_number(data), do: :ok
  defp do_validate(data, %{type: "boolean"}) when is_boolean(data), do: :ok
  defp do_validate(data, %{type: "array"}) when is_list(data), do: :ok
  defp do_validate(data, %{type: "object"}) when is_map(data), do: :ok
  defp do_validate(_data, _schema), do: {:error, :type_mismatch}

  defp validate_required_fields(data, required) when is_list(required) do
    missing =
      Enum.filter(required, fn field ->
        not Map.has_key?(data, field) and not Map.has_key?(data, String.to_atom(field))
      end)

    if Enum.empty?(missing) do
      :ok
    else
      {:error, {:missing_required_fields, missing}}
    end
  end

  defp validate_required_fields(_data, _required), do: :ok

  defp validate_properties(data, properties) when is_map(properties) do
    Enum.reduce_while(properties, :ok, fn {key, schema}, _acc ->
      value = Map.get(data, key) || Map.get(data, String.to_atom(key))

      if value do
        case do_validate(value, schema) do
          :ok -> {:cont, :ok}
          error -> {:halt, error}
        end
      else
        {:cont, :ok}
      end
    end)
  end

  defp validate_properties(_data, _properties), do: :ok
end
