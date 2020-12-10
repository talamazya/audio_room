defmodule JanusEx.JanusChannel do
  use GenServer, restart: :temporary

  alias JanusEx.JanusApi.Plugin.AudioBridge.AudioBridge
  alias Janus.WS, as: Janus
  alias JanusEx.Room

  @moduledoc """
    Steps to setup connection : web client <---> phoenix <---> Janus gateway:
    1. session:         web --> phoenix --> Janus --> phoenix (process_session)
    2. attach:          phoenix --> janus --> phoenix (process_handle)
    3. create room:     phoenix --> janus --> phoenix (process_create)
    4. join:            phoenix --> janus --> phoenix (process_join)
    5. offer:           phoenix --> web --> phoenix --> janus --> phoenix (process_non_transaction)
    6. candidate:       phoenix --> web --> phoenix --> janus --> phoenix (process_candidate)
  """

  # opts = %{pid: pid, room_name: room_name}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(state) do
    {:ok, state}
  end

  def create_session(pid) do
    GenServer.call(pid, :create_session)
  end

  def offer(pid, offer) do
    GenServer.call(pid, {:offer, offer})
  end

  def candidate(pid, candidate) do
    GenServer.call(pid, {:candidate, candidate})
  end

  def participants(pid) do
    GenServer.call(pid, :participants)
  end

  def mute(pid, participant_id) do
    GenServer.call(pid, {:mute, participant_id})
  end

  def leave_room(pid) do
    GenServer.call(pid, :leave)
  end

  def handle_call(:create_session, _from, state) do
    {:ok, tx_id} = AudioBridge.create_session()

    {:reply, :ok, Map.put(state, :txs, %{tx_id => :session})}
  end

  def handle_call({:offer, offer}, _from, state) do
    %{session_id: session_id, handle_id: handle_id, txs: txs} = state

    {:ok, tx_id} = AudioBridge.offer(session_id, handle_id, offer)

    txs = Map.put(txs, :configure, tx_id)

    {:reply, :ok, Map.put(state, :txs, txs)}
  end

  def handle_call({:candidate, candidate}, _from, state) do
    %{session_id: session_id, handle_id: handle_id, txs: txs} = state

    {:ok, tx_id} = AudioBridge.trickle_candidate(session_id, handle_id, candidate)
    txs = Map.put(txs, tx_id, :candidate)

    {:reply, :ok, Map.put(state, :txs, txs)}
  end

  def handle_call(:participants, _from, state) do
    %{session_id: session_id, handle_id: handle_id, room_id: room_id, txs: txs} = state

    {:ok, tx_id} = AudioBridge.participants(session_id, handle_id, room_id)
    txs = Map.put(txs, tx_id, :participants)

    {:reply, :ok, Map.put(state, :txs, txs)}
  end

  def handle_call({:mute, participant_id}, _from, state) do
    %{session_id: session_id, handle_id: handle_id, room_id: room_id, txs: txs} = state

    {:ok, tx_id} = AudioBridge.mute(session_id, handle_id, room_id, participant_id)
    txs = Map.put(txs, tx_id, :mute)

    {:reply, :ok, Map.put(state, :txs, txs)}
  end

  def handle_call(:leave, _from, state) do
    %{room_name: room_name, room_id: room_id, participant_id: participant_id} = state
    Room.leave(room_name, room_id, participant_id)

    {:reply, :ok, state}
  end

  def handle_info(:keepalive, %{session_id: session_id} = state) do
    AudioBridge.keep_alive(session_id)
    Process.send_after(self(), :keepalive, 30_000)

    {:noreply, state}
  end

  def handle_info({:janus_ws, msg}, state) do
    {:noreply, handle_janus_msg(state, msg)}
  end

  defp handle_janus_msg(%{txs: txs} = state, %{"transaction" => tx_id} = msg) do
    Map.pop(txs, tx_id)
    |> case do
      {:session, txs} ->
        process_session(state, txs, msg)

      {:handle, txs} ->
        process_handle(state, txs, msg)

      {:create, txs} ->
        process_create(state, txs, msg)

      {:join, txs} ->
        process_join(state, txs, msg)

      {:candidate, txs} ->
        process_candidate(state, txs, msg)

      {:participants, txs} ->
        process_participants(state, txs, msg)

      {:mute, txs} ->
        process_mute(state, txs, msg)

      {nil, _txs} ->
        process_non_transaction(state, msg)
    end
  end

  defp handle_janus_msg(state, msg) do
    IO.inspect(msg, label: "unexpected socket message")
    state
  end

  defp process_session(state, txs, msg) do
    %{"janus" => "success", "data" => %{"id" => session_id}} = msg

    {:ok, _owner_id} = Registry.register(Janus.Session.Registry, session_id, [])
    {:ok, tx_id} = AudioBridge.attach(session_id)
    Process.send_after(self(), :keepalive, 30_000)

    state
    |> Map.put(:session_id, session_id)
    |> Map.put(:txs, Map.put(txs, tx_id, :handle))
  end

  defp process_handle(state, txs, msg) do
    %{session_id: session_id, room_name: room_name} = state
    handle_id = AudioBridge.attach_response(msg, session_id)
    state = Map.put(state, :handle_id, handle_id)

    {exist?, room_id} = Room.exist?(room_name)

    if exist? do
      {:ok, tx_id} = AudioBridge.join(session_id, handle_id, room_id)

      Map.put(state, :txs, Map.put(txs, tx_id, :join))
    else
      {:ok, tx_id} = AudioBridge.create(session_id, handle_id, room_id, room_name)

      Map.put(state, :txs, Map.put(txs, tx_id, :create))
    end
  end

  defp process_create(state, txs, msg) do
    %{session_id: session_id, handle_id: handle_id, room_name: room_name} = state
    room_id = AudioBridge.create_response(msg, session_id, handle_id)

    Room.create(room_name, room_id)

    {:ok, tx_id} = AudioBridge.join(session_id, handle_id, room_id)

    Map.put(state, :txs, Map.put(txs, tx_id, :join))
  end

  defp process_join(state, _txs, %{"janus" => "ack"}), do: state

  defp process_join(%{handle_id: handle_id, session_id: session_id} = state, txs, msg) do
    send(Map.get(state, :pid), {:gimme_offer, "gimme_offer"})

    {participant_id, room_id} = AudioBridge.join_response(session_id, handle_id, msg)

    Room.participant(Map.get(state, :room_name), participant_id)

    state
    |> Map.put(:txs, txs)
    |> Map.put(:participant_id, participant_id)
    |> Map.put(:room_id, room_id)
  end

  defp process_candidate(state, txs, msg) do
    %{session_id: session_id} = state
    %{"janus" => "ack", "session_id" => ^session_id} = msg
    Map.put(state, :txs, txs)
  end

  defp process_participants(state, txs, msg) do
    %{session_id: session_id, handle_id: handle_id, room_id: room_id} = state
    participants = AudioBridge.participants_response(session_id, handle_id, room_id, msg)

    send(Map.get(state, :pid), {:participants, participants})

    Map.put(state, :txs, txs)
  end

  defp process_mute(state, txs, msg) do
    IO.inspect(msg)
    Map.put(state, :txs, txs)
  end

  defp process_non_transaction(
         %{session_id: session_id, handle_id: handle_id} = state,
         %{"sender" => handle_id, "session_id" => session_id} = msg
       ) do
    process_event(state, msg)
  end

  defp process_non_transaction(state, msg) do
    IO.inspect(msg, label: "unexpected socket tx message")
    state
  end

  defp process_event(state, %{"jsep" => %{"type" => "answer"} = answer}) do
    send(Map.get(state, :pid), {:answer, answer})
    state
  end

  defp process_event(state, msg) do
    IO.inspect(msg, label: "event has not been supported yet!")
    state
  end
end
