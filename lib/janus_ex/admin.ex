defmodule JanusEx.Admin do
  use GenServer

  alias JanusEx.JanusApi.Plugin.AudioBridge.RestApi.SessionService
  alias JanusEx.JanusApi.Plugin.AudioBridge.RestApi.AdminService
  alias JanusEx.JanusApi.Plugin.AudioBridge.Websocket.AudioBridge

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state, {:continue, :janus_session}}
  end

  def mute(room_id, participant_id, mute?) do
    GenServer.call(__MODULE__, {:mute, room_id, participant_id, mute?})
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

  def handle_call({:mute, room_id, participant_id, mute?}, _from, state) do
    %{session_id: session_id, handle_id: handle_id} = state

    with {:ok, msg} <- AdminService.mute(session_id, handle_id, room_id, participant_id, mute?) do
      {:reply, {:ok, msg}, state}
    else
      {:error, msg} -> {:reply, {:error, msg}, state}
    end
  end

  def handle_info(:keepalive, %{session_id: session_id} = state) do
    SessionService.keep_alive(session_id)

    Process.send_after(self(), :keepalive, 30_000)

    {:noreply, state}
  end
end
