defmodule Glossary.AI.LLM do
  @moduledoc """
  OpenAI-compatible chat completions client.

  Works with both Ollama (local, default) and OpenAI (cloud fallback)
  since Ollama exposes an OpenAI-compatible API at `/v1/chat/completions`.

  Configure via application config:

      config :glossary, Glossary.AI.LLM,
        base_url: "http://localhost:11434/v1",
        api_key: "ollama",
        model: "llama3.2"
  """

  @doc """
  Sends a chat completion request and returns the assistant's response content.
  """
  def chat(messages, opts \\ []) do
    config = config()
    model = Keyword.get(opts, :model, config.model)

    body = %{
      model: model,
      messages: messages,
      stream: false
    }

    case Req.post(
           "#{config.base_url}/chat/completions",
           json: body,
           auth: {:bearer, config.api_key},
           receive_timeout: 120_000
         ) do
      {:ok, %{status: 200, body: body}} ->
        content = get_in(body, ["choices", Access.at(0), "message", "content"])
        {:ok, content}

      {:ok, %{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp config do
    app_config = Application.get_env(:glossary, __MODULE__, [])

    %{
      base_url: Keyword.get(app_config, :base_url, "http://localhost:11434/v1"),
      api_key: Keyword.get(app_config, :api_key, "ollama"),
      model: Keyword.get(app_config, :model, "llama3.2")
    }
  end
end
