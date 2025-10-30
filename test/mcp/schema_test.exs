defmodule MCP.SchemaTest do
  use ExUnit.Case
  alias MCP.Schema

  describe "to_json_schema/1" do
    test "converts simple type map to JSON Schema" do
      schema = Schema.to_json_schema(%{name: :string, age: :integer})

      assert schema.type == "object"
      assert schema.properties["name"] == %{type: "string"}
      assert schema.properties["age"] == %{type: "integer"}
      assert "name" in schema.required
      assert "age" in schema.required
    end

    test "handles multiple types" do
      schema = Schema.to_json_schema(%{
        str: :string,
        num: :number,
        bool: :boolean,
        arr: :array,
        obj: :object
      })

      assert schema.properties["str"][:type] == "string"
      assert schema.properties["num"][:type] == "number"
      assert schema.properties["bool"][:type] == "boolean"
      assert schema.properties["arr"][:type] == "array"
      assert schema.properties["obj"][:type] == "object"
    end
  end

  describe "string/1" do
    test "creates string schema" do
      schema = Schema.string()
      assert schema.type == "string"
    end

    test "adds description" do
      schema = Schema.string(description: "User name")
      assert schema.description == "User name"
    end

    test "adds length constraints" do
      schema = Schema.string(min_length: 1, max_length: 100)
      assert schema.minLength == 1
      assert schema.maxLength == 100
    end
  end

  describe "integer/1" do
    test "creates integer schema" do
      schema = Schema.integer()
      assert schema.type == "integer"
    end

    test "adds range constraints" do
      schema = Schema.integer(minimum: 0, maximum: 150)
      assert schema.minimum == 0
      assert schema.maximum == 150
    end
  end

  describe "number/1" do
    test "creates number schema" do
      schema = Schema.number()
      assert schema.type == "number"
    end
  end

  describe "boolean/1" do
    test "creates boolean schema" do
      schema = Schema.boolean()
      assert schema.type == "boolean"
    end
  end

  describe "array/1" do
    test "creates array schema" do
      schema = Schema.array()
      assert schema.type == "array"
    end

    test "adds array constraints" do
      schema = Schema.array(min_items: 1, max_items: 10)
      assert schema.minItems == 1
      assert schema.maxItems == 10
    end
  end

  describe "validate/2" do
    test "validates string type" do
      schema = %{type: "string"}
      assert {:ok, "test"} = Schema.validate("test", schema)
      assert {:error, :type_mismatch} = Schema.validate(123, schema)
    end

    test "validates integer type" do
      schema = %{type: "integer"}
      assert {:ok, 42} = Schema.validate(42, schema)
      assert {:error, :type_mismatch} = Schema.validate("42", schema)
    end

    test "validates object with required fields" do
      schema = %{
        type: "object",
        properties: %{
          name: %{type: "string"},
          age: %{type: "integer"}
        },
        required: ["name", "age"]
      }

      assert {:ok, _} = Schema.validate(%{name: "John", age: 30}, schema)
      assert {:error, {:missing_required_fields, _}} =
               Schema.validate(%{name: "John"}, schema)
    end

    test "validates object with atom keys" do
      schema = %{
        type: "object",
        properties: %{
          name: %{type: "string"}
        },
        required: ["name"]
      }

      assert {:ok, _} = Schema.validate(%{name: "John"}, schema)
    end
  end
end
