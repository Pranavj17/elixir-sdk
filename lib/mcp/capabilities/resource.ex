defmodule MCP.Capabilities.Resource do
  @moduledoc """
  Resource capability for MCP servers.

  Resources represent data that can be read by the AI. They are identified
  by URIs and can be static or dynamic (with URI templates).
  """

  @type t :: %__MODULE__{
          uri: String.t(),
          name: String.t(),
          description: String.t() | nil,
          mime_type: String.t(),
          handler: function()
        }

  defstruct [:uri, :name, :description, :mime_type, :handler]

  @doc """
  Creates a new resource definition.

  ## Parameters
  - `uri` - Resource URI or URI template (e.g., "file:///{path}" or "user://{user_id}")
  - `name` - Resource name
  - `description` - Human-readable description (optional)
  - `mime_type` - MIME type of the resource (default: "text/plain")
  - `handler` - Function that returns resource content (arity 1, receives URI params)

  ## Examples

      # Static resource
      resource = Resource.new(
        "config://version",
        "Version",
        "Application version",
        "text/plain",
        fn _params -> "1.0.0" end
      )

      # Dynamic resource
      resource = Resource.new(
        "user://{user_id}/profile",
        "User Profile",
        "User profile data",
        "application/json",
        fn %{user_id: uid} ->
          Jason.encode!(%{id: uid, name: "User \#{uid}"})
        end
      )
  """
  def new(uri, name, description \\ nil, mime_type \\ "text/plain", handler)
      when is_binary(uri) and is_binary(name) and is_function(handler, 1) do
    %__MODULE__{
      uri: uri,
      name: name,
      description: description,
      mime_type: mime_type,
      handler: handler
    }
  end

  @doc """
  Converts a resource to the MCP resources/list response format.
  """
  def to_list_format(%__MODULE__{} = resource) do
    base = %{
      uri: resource.uri,
      name: resource.name,
      mimeType: resource.mime_type
    }

    if resource.description do
      Map.put(base, :description, resource.description)
    else
      base
    end
  end

  @doc """
  Reads a resource by matching the URI and extracting parameters.

  Returns `{:ok, contents}` or `{:error, reason}`.
  """
  def read(%__MODULE__{} = resource, uri) do
    with {:ok, params} <- match_uri(resource.uri, uri),
         {:ok, content} <- call_handler(resource.handler, params) do
      {:ok, format_content(uri, content, resource.mime_type)}
    end
  rescue
    error ->
      {:error, %{message: Exception.message(error), type: error.__struct__}}
  end

  # Private functions

  defp match_uri(template, uri) do
    # Extract parameters from URI template
    # e.g., "user://{user_id}" matches "user://123" -> %{user_id: "123"}
    regex = template_to_regex(template)

    if Regex.match?(regex, uri) do
      captures = Regex.named_captures(regex, uri)
      params = for {k, v} <- captures, into: %{}, do: {String.to_atom(k), v}
      {:ok, params}
    else
      {:error, :uri_not_matched}
    end
  end

  defp template_to_regex(template) do
    # Convert URI template to regex pattern
    # "{param}" -> "(?<param>[^/]+)"
    pattern =
      template
      |> String.replace(~r/\{(\w+)\}/, "(?<\\1>[^/]+)")
      |> Regex.escape()
      |> String.replace("\\(\\?\\<", "(?<")
      |> String.replace("\\>\\[\\^/\\]\\+\\)", ">[^/]+)")

    Regex.compile!("^#{pattern}$")
  end

  defp call_handler(handler, params) do
    try do
      result = handler.(params)
      {:ok, result}
    rescue
      error -> {:error, Exception.message(error)}
    end
  end

  defp format_content(uri, content, mime_type) when is_binary(content) do
    %{
      contents: [
        %{
          uri: uri,
          mimeType: mime_type,
          text: content
        }
      ]
    }
  end

  defp format_content(uri, content, mime_type) when is_map(content) do
    # If content already has MCP format, return as-is
    if Map.has_key?(content, :contents) or Map.has_key?(content, "contents") do
      content
    else
      # Otherwise, encode to JSON
      %{
        contents: [
          %{
            uri: uri,
            mimeType: mime_type,
            text: Jason.encode!(content)
          }
        ]
      }
    end
  end

  defp format_content(uri, content, mime_type) do
    %{
      contents: [
        %{
          uri: uri,
          mimeType: mime_type,
          text: inspect(content)
        }
      ]
    }
  end
end
