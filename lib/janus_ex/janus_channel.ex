defmodule JanusEx.JanusChannel do
  use GenServer, restart: :temporary

  alias Janus.WS, as: Janus
  alias JanusEx.Room

  alias JanusEx.JanusApi.Plugin.AudioBridge.AudioBridge

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
    txs = Map.put(txs, tx_id, :trickle)

    {:reply, :ok, Map.put(state, :txs, txs)}
  end

  def handle_info(:keepalive, %{session_id: session_id} = state) do
    AudioBridge.keep_alive(session_id)
    Process.send_after(self(), :keepalive, 30_000)

    {:noreply, state}
  end

  def handle_info(:join_janus_room, state) do
    %{room_name: room_name, session_id: session_id, handle_id: handle_id, txs: txs} = state

    state =
      if Room.janus_room_created?(room_name) do
        room_id = Room.janus_room_id(room_name)
        {:ok, tx_id} = AudioBridge.join(session_id, handle_id, room_id)

        Map.put(state, :txs, Map.put(txs, tx_id, :join))
      else
        Process.send_after(self(), :join_janus_room, 1000)
        state
      end

    {:noreply, state}
  end

  def handle_info({:janus_ws, msg}, state) do
    state = state |> handle_janus_msg(msg)

    {:noreply, state}
  end

  # step1: session
  # step2: handle
  # step3: join
  # step4: send message: "gimme_offer" from channel --> web
  # step5: config (offer)
  # step6: trickle
  defp handle_janus_msg(%{txs: txs} = state, %{"transaction" => tx_id} = msg) do
    Map.pop(txs, tx_id)
    |> case do
      {:session, txs} ->
        process_session(state, txs, msg)

      {:handle, txs} ->
        process_handle(state, txs, msg)

      {:join, txs} ->
        process_join(state, txs, msg)

      {:trickle, txs} ->
        process_trickle(state, txs, msg)

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

    state =
      Room.janus_room_created?(room_name)
      |> if do
        {:ok, tx_id} = AudioBridge.join(session_id, handle_id, Room.janus_room_id(room_name))

        Map.put(state, :txs, Map.put(txs, tx_id, :join))
      else
        Process.send_after(self(), :join_janus_room, 1000)
        Map.put(state, :txs, txs)
      end

    Map.put(state, :handle_id, handle_id)
  end

  defp process_join(state, _txs, %{"janus" => "ack"}), do: state

  defp process_join(%{handle_id: handle_id, session_id: session_id} = state, txs, msg) do
    send(Map.get(state, :pid), {:gimme_offer, "gimme_offer"})

    {participant_id, room_id} = AudioBridge.join_response(session_id, handle_id, msg)

    state
    |> Map.put(:txs, txs)
    |> Map.put(:participant_id, participant_id)
    |> Map.put(:room_id, room_id)
  end

  defp process_trickle(state, txs, msg) do
    %{session_id: session_id} = state
    %{"janus" => "ack", "session_id" => ^session_id} = msg
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
