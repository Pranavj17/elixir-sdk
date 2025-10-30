defmodule MCPTest do
  use ExUnit.Case
  doctest MCP

  test "returns correct SDK version" do
    assert is_binary(MCP.version())
    assert MCP.version() == "0.1.0"
  end

  test "returns correct protocol version" do
    assert MCP.protocol_version() == "2024-11-05"
  end
end
