defmodule JanusEx.Admin do
  use GenServer

  alias JanusEx.RestApi.SessionService
  alias JanusEx.JanusApi.Plugin.AudioBridge.AudioBridge

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state, {:continue, :janus_session}}
  end

  def handle_continue(:janus_session, state) do
    with {:ok, session_id} <- SessionService.create(),
         {:ok, handle_id} <- SessionService.attach_plugin(session_id, AudioBridge.plugin_name()) do
      state =
        state
        |> Map.put(:session_id, session_id)
        |> Map.put(:handle_id, handle_id)

      Process.send_after(self(), :keepalive, 30_000)

      {:noreply, state}
    else
      _ -> :init.stop()
    end
  end

  def handle_info(:keepalive, %{session_id: session_id} = state) do
    SessionService.keep_alive(session_id)

    Process.send_after(self(), :keepalive, 30_000)

    {:noreply, state}
  end
end
