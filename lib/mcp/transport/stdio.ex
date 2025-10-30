defmodule MCP.Transport.Stdio do
  @moduledoc """
  Standard I/O transport for MCP servers.

  Reads JSON-RPC messages from stdin and writes responses to stdout.
  This is the primary transport for local MCP servers used by desktop applications.
  """

  use GenServer
  require Logger

  @type state :: %{
          server: pid(),
          buffer: String.t()
        }

  ## Client API

  @doc """
  Starts the stdio transport.

  ## Options
  - `:server` - PID of the MCP server process (required)
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Writes a message to stdout.
  """
  def write(message) when is_map(message) do
    GenServer.call(__MODULE__, {:write, message})
  end

  ## GenServer Callbacks

  @impl true
  def init(opts) do
    server = Keyword.fetch!(opts, :server)

    # Start reading from stdin
    spawn_link(fn -> read_loop() end)

    {:ok, %{server: server, buffer: ""}}
  end

  @impl true
  def handle_call({:write, message}, _from, state) do
    result = do_write(message)
    {:reply, result, state}
  end

  @impl true
  def handle_info({:stdin, line}, state) do
    # Process incoming line
    case Jason.decode(line) do
      {:ok, message} ->
        # Forward to server
        send(state.server, {:mcp_message, message})
        {:noreply, state}

      {:error, _} ->
        Logger.warning("Failed to decode JSON: #{inspect(line)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:mcp_response, response}, state) do
    # Write response to stdout
    do_write(response)
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  ## Private Functions

  defp read_loop do
    IO.stream(:stdio, :line)
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == ""))
    |> Enum.each(fn line ->
      send(__MODULE__, {:stdin, line})
    end)
  end

  defp do_write(message) do
    case Jason.encode(message) do
      {:ok, json} ->
        IO.puts(json)
        :ok

      {:error, reason} ->
        Logger.error("Failed to encode JSON: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
