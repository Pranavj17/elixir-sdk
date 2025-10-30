defmodule MCP.Server do
  @moduledoc """
  MCP Server behavior and implementation.

  Provides a high-level API for building Model Context Protocol servers.
  Handles protocol compliance, message routing, and capability management.

  ## Usage

      defmodule MyServer do
        use MCP.Server

        def init(_opts) do
          state = %{
            name: "my-server",
            version: "1.0.0"
          }

          {:ok, state}
        end

        def handle_init(state) do
          # Register capabilities during initialization
          server = self()

          MCP.Server.register_tool(
            server,
            "add",
            "Adds two numbers",
            %{a: :number, b: :number},
            fn %{a: a, b: b} -> a + b end
          )

          {:ok, state}
        end
      end

      # Start the server
      {:ok, pid} = MyServer.start_link()
  """

  use GenServer
  require Logger

  alias MCP.Protocol.Message
  alias MCP.Capabilities.{Tool, Resource, Prompt}

  @type state :: %{
          name: String.t(),
          version: String.t(),
          tools: %{String.t() => Tool.t()},
          resources: %{String.t() => Resource.t()},
          prompts: %{String.t() => Prompt.t()},
          user_state: any()
        }

  @callback init(opts :: keyword()) :: {:ok, state :: any()} | {:error, reason :: any()}
  @callback handle_init(state :: any()) :: {:ok, state :: any()} | {:error, reason :: any()}

  defmacro __using__(_opts) do
    quote do
      @behaviour MCP.Server
      use GenServer

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      @impl GenServer
      def init(opts) do
        case __MODULE__.init(opts) do
          {:ok, user_state} ->
            state = %{
              name: Keyword.get(opts, :name, "mcp-server"),
              version: Keyword.get(opts, :version, "0.1.0"),
              tools: %{},
              resources: %{},
              prompts: %{},
              user_state: user_state
            }

            case __MODULE__.handle_init(user_state) do
              {:ok, new_user_state} ->
                {:ok, %{state | user_state: new_user_state}}

              {:error, reason} ->
                {:stop, reason}
            end

          {:error, reason} ->
            {:stop, reason}
        end
      end

      def handle_init(state), do: {:ok, state}

      defoverridable handle_init: 1
    end
  end

  ## Client API

  @doc """
  Registers a tool with the server.
  """
  def register_tool(server, name, description, input_schema, handler) do
    tool = Tool.new(name, description, input_schema, handler)
    GenServer.call(server, {:register_tool, tool})
  end

  @doc """
  Registers a resource with the server.
  """
  def register_resource(server, uri, name, description \\ nil, mime_type \\ "text/plain", handler) do
    resource = Resource.new(uri, name, description, mime_type, handler)
    GenServer.call(server, {:register_resource, resource})
  end

  @doc """
  Registers a prompt with the server.
  """
  def register_prompt(server, name, description \\ nil, arguments \\ [], handler) do
    prompt = Prompt.new(name, description, arguments, handler)
    GenServer.call(server, {:register_prompt, prompt})
  end

  ## GenServer Callbacks

  @impl true
  def handle_call({:register_tool, tool}, _from, state) do
    new_state = put_in(state, [:tools, tool.name], tool)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:register_resource, resource}, _from, state) do
    key = resource.uri
    new_state = put_in(state, [:resources, key], resource)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:register_prompt, prompt}, _from, state) do
    new_state = put_in(state, [:prompts, prompt.name], prompt)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info({:mcp_message, message}, state) do
    response = handle_message(message, state)

    # Send response to transport
    send(self(), {:mcp_response, response})

    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  ## Message Handling

  @doc """
  Handles an MCP protocol message.
  """
  def handle_message(message, state) do
    case Message.validate(message) do
      {:ok, valid_message} ->
        process_message(valid_message, state)

      {:error, reason} ->
        Message.error_response(
          Map.get(message, "id"),
          Message.error_code(:invalid_request),
          "Invalid message: #{inspect(reason)}"
        )
    end
  end

  defp process_message(%{"method" => "initialize"} = msg, state) do
    Message.response(msg["id"], %{
      protocolVersion: "2024-11-05",
      capabilities: %{
        tools: %{},
        resources: %{},
        prompts: %{}
      },
      serverInfo: %{
        name: state.name,
        version: state.version
      }
    })
  end

  defp process_message(%{"method" => "tools/list"}, state) do
    tools =
      state.tools
      |> Map.values()
      |> Enum.map(&Tool.to_list_format/1)

    Message.response(nil, %{tools: tools})
  end

  defp process_message(%{"method" => "tools/call", "params" => params} = msg, state) do
    tool_name = params["name"]
    arguments = params["arguments"] || %{}

    case Map.get(state.tools, tool_name) do
      nil ->
        Message.error_response(
          msg["id"],
          Message.error_code(:method_not_found),
          "Tool not found: #{tool_name}"
        )

      tool ->
        case Tool.execute(tool, arguments) do
          {:ok, result} ->
            Message.response(msg["id"], result)

          {:error, reason} ->
            Message.error_response(
              msg["id"],
              Message.error_code(:internal_error),
              "Tool execution failed: #{inspect(reason)}"
            )
        end
    end
  end

  defp process_message(%{"method" => "resources/list"}, state) do
    resources =
      state.resources
      |> Map.values()
      |> Enum.map(&Resource.to_list_format/1)

    Message.response(nil, %{resources: resources})
  end

  defp process_message(%{"method" => "resources/read", "params" => params} = msg, state) do
    uri = params["uri"]

    # Find matching resource
    resource =
      state.resources
      |> Map.values()
      |> Enum.find(fn res ->
        String.starts_with?(uri, String.split(res.uri, "{") |> List.first())
      end)

    case resource do
      nil ->
        Message.error_response(
          msg["id"],
          Message.error_code(:method_not_found),
          "Resource not found: #{uri}"
        )

      resource ->
        case Resource.read(resource, uri) do
          {:ok, result} ->
            Message.response(msg["id"], result)

          {:error, reason} ->
            Message.error_response(
              msg["id"],
              Message.error_code(:internal_error),
              "Resource read failed: #{inspect(reason)}"
            )
        end
    end
  end

  defp process_message(%{"method" => "prompts/list"}, state) do
    prompts =
      state.prompts
      |> Map.values()
      |> Enum.map(&Prompt.to_list_format/1)

    Message.response(nil, %{prompts: prompts})
  end

  defp process_message(%{"method" => "prompts/get", "params" => params} = msg, state) do
    prompt_name = params["name"]
    arguments = params["arguments"] || %{}

    case Map.get(state.prompts, prompt_name) do
      nil ->
        Message.error_response(
          msg["id"],
          Message.error_code(:method_not_found),
          "Prompt not found: #{prompt_name}"
        )

      prompt ->
        case Prompt.execute(prompt, arguments) do
          {:ok, result} ->
            Message.response(msg["id"], result)

          {:error, reason} ->
            Message.error_response(
              msg["id"],
              Message.error_code(:internal_error),
              "Prompt execution failed: #{inspect(reason)}"
            )
        end
    end
  end

  defp process_message(%{"method" => "notifications/" <> _}, _state) do
    # Notifications don't get responses
    nil
  end

  defp process_message(%{"method" => method} = msg, _state) do
    Message.error_response(
      msg["id"],
      Message.error_code(:method_not_found),
      "Unknown method: #{method}"
    )
  end

  defp process_message(_msg, _state) do
    Message.error_response(
      nil,
      Message.error_code(:invalid_request),
      "Invalid message format"
    )
  end
end
