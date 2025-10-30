defmodule MCP.Protocol.MessageTest do
  use ExUnit.Case
  alias MCP.Protocol.Message

  describe "request/3" do
    test "creates a valid JSON-RPC request" do
      msg = Message.request(1, "test/method", %{key: "value"})

      assert msg.jsonrpc == "2.0"
      assert msg.id == 1
      assert msg.method == "test/method"
      assert msg.params == %{key: "value"}
    end

    test "creates request without params" do
      msg = Message.request(1, "test/method")

      assert msg.jsonrpc == "2.0"
      assert msg.id == 1
      assert msg.method == "test/method"
      refute Map.has_key?(msg, :params)
    end
  end

  describe "notification/2" do
    test "creates a notification without id" do
      msg = Message.notification("test/notify", %{data: "test"})

      assert msg.jsonrpc == "2.0"
      assert msg.method == "test/notify"
      assert msg.params == %{data: "test"}
      refute Map.has_key?(msg, :id)
    end
  end

  describe "response/2" do
    test "creates a success response" do
      msg = Message.response(1, %{result: "success"})

      assert msg.jsonrpc == "2.0"
      assert msg.id == 1
      assert msg.result == %{result: "success"}
    end
  end

  describe "error_response/4" do
    test "creates an error response" do
      msg = Message.error_response(1, -32600, "Invalid request")

      assert msg.jsonrpc == "2.0"
      assert msg.id == 1
      assert msg.error.code == -32600
      assert msg.error.message == "Invalid request"
    end

    test "includes error data when provided" do
      msg = Message.error_response(1, -32600, "Invalid", %{detail: "test"})

      assert msg.error.data == %{detail: "test"}
    end
  end

  describe "error_code/1" do
    test "returns correct error codes" do
      assert Message.error_code(:parse_error) == -32700
      assert Message.error_code(:invalid_request) == -32600
      assert Message.error_code(:method_not_found) == -32601
      assert Message.error_code(:invalid_params) == -32602
      assert Message.error_code(:internal_error) == -32603
    end
  end

  describe "validate/1" do
    test "validates correct JSON-RPC 2.0 request" do
      msg = %{"jsonrpc" => "2.0", "method" => "test", "id" => 1}
      assert {:ok, ^msg} = Message.validate(msg)
    end

    test "validates correct JSON-RPC 2.0 response" do
      msg = %{"jsonrpc" => "2.0", "result" => %{}, "id" => 1}
      assert {:ok, ^msg} = Message.validate(msg)
    end

    test "rejects invalid jsonrpc version" do
      msg = %{"jsonrpc" => "1.0", "method" => "test"}
      assert {:error, :invalid_jsonrpc_version} = Message.validate(msg)
    end

    test "rejects message without jsonrpc field" do
      msg = %{"method" => "test"}
      assert {:error, _} = Message.validate(msg)
    end

    test "rejects non-map messages" do
      assert {:error, :invalid_message} = Message.validate("not a map")
    end
  end
end
