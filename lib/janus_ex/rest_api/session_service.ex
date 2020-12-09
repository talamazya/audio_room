defmodule JanusEx.RestApi.SessionService do
  alias JanusEx.RestApi.RestClient

  def create do
    data = %{janus: "create", transaction: transaction()}

    case RestClient.post("janus", data) do
      {:ok, %{"data" => %{"id" => session_id}, "janus" => "success", "transaction" => _}} ->
        {:ok, session_id}

      _ ->
        {:error, nil}
    end
  end

  @doc """
  API call to Janus to create a handler for the plugin.
  """
  def attach_plugin(session_id, plugin) when is_integer(session_id) do
    data = %{janus: "attach", transaction: transaction(), plugin: plugin}

    case RestClient.post("janus/#{session_id}", data) do
      {:ok, %{"data" => %{"id" => handle_id}, "janus" => "success", "session_id" => ^session_id}} ->
        {:ok, handle_id}

      {:error, _} ->
        {:error, nil}
    end
  end

  def keep_alive(session_id) do
    data = %{janus: "keepalive", transaction: transaction(), session_id: session_id}

    case RestClient.post("janus/#{session_id}", data) do
      {:ok, %{"janus" => "ack", "session_id" => ^session_id, "transaction" => _}} ->
        {:ok, session_id}

      {:error, _} ->
        {:error, nil}
    end
  end

  defp transaction() do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode64(padding: false)
  end
end
