defmodule JanusEx.JanusChannel do
  use GenServer, restart: :temporary

  alias Janus.WS, as: Janus
  alias JanusEx.Room

  @client Janus

  # opts = %{pid: pid, room_name: room_name}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(state) do
    {:ok, state}
  end

  def join(pid) do
    GenServer.call(pid, :join)
  end

  def offer(pid, offer) do
    GenServer.call(pid, {:offer, offer})
  end

  def candidate(pid, candidate) do
    GenServer.call(pid, {:candidate, candidate})
  end

  def handle_call(:join, _from, state) do
    {:ok, tx_id} = Janus.create_session(@client)

    state = state |> Map.put(:txs, %{tx_id => :session})

    {:reply, :ok, state}
  end

  def handle_call({:offer, offer}, _from, state) do
    %{session_id: session_id, handle_id: handle_id, txs: txs} = state

    {:ok, tx_id} =
      Janus.send_message(@client, session_id, handle_id, %{
        "jsep" => offer,
        "body" => %{"request" => "configure"}
      })

    state = state |> Map.put(:txs, Map.put(txs, :configure, tx_id))

    {:reply, :ok, state}
  end

  def handle_call({:candidate, candidate}, _from, state) do
    %{session_id: session_id, handle_id: handle_id, txs: txs} = state

    {:ok, tx_id} = Janus.send_trickle_candidate(@client, session_id, handle_id, candidate)

    state = state |> Map.put(:txs, Map.put(txs, tx_id, :trickle))

    {:reply, :ok, state}
  end

  def handle_info(:keepalive, %{session_id: session_id} = state) do
    Janus.send_keepalive(@client, session_id)
    Process.send_after(self(), :keepalive, 30_000)
    {:noreply, state}
  end

  def handle_info(:join_janus_room, state) do
    %{room_name: room_name, session_id: session_id, handle_id: handle_id, txs: txs} = state

    state =
      if Room.janus_room_created?(room_name) do
        {:ok, tx_id} =
          Janus.send_message(@client, session_id, handle_id, %{
            "body" => %{
              "request" => "join",
              "room" => Room.janus_room_id(room_name)
            }
          })

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
  # step5: config
  # step6: trickle
  defp handle_janus_msg(%{txs: txs} = state, %{"transaction" => tx_id} = msg) do
    Map.pop(txs, tx_id)
    |> case do
      {:session, txs} ->
        %{"janus" => "success", "data" => %{"id" => session_id}} = msg
        {:ok, _owner_id} = Registry.register(Janus.Session.Registry, session_id, [])
        {:ok, tx_id} = Janus.attach(@client, session_id, "janus.plugin.audiobridge")
        Process.send_after(self(), :keepalive, 30_000)

        state
        |> Map.put(:session_id, session_id)
        |> Map.put(:txs, Map.put(txs, tx_id, :handle))

      {:handle, txs} ->
        %{session_id: session_id} = state

        %{
          "data" => %{"id" => handle_id},
          "janus" => "success",
          "session_id" => ^session_id,
          "transaction" => ^tx_id
        } = msg

        room_name = Map.get(state, :room_name)

        state =
          Room.janus_room_created?(room_name)
          |> if do
            {:ok, tx_id} =
              Janus.send_message(@client, session_id, handle_id, %{
                "body" => %{
                  "request" => "join",
                  "room" => Room.janus_room_id(room_name)
                }
              })

            Map.put(state, :txs, Map.put(txs, tx_id, :join))
          else
            Process.send_after(self(), :join_janus_room, 1000)
            Map.put(state, :txs, txs)
          end

        Map.put(state, :handle_id, handle_id)

      {:join, txs} ->
        %{handle_id: handle_id, session_id: session_id} = state

        case msg do
          %{"janus" => "ack", "session_id" => ^session_id} ->
            state

          %{
            "janus" => "event",
            "plugindata" => %{
              "data" => %{
                "audiobridge" => "joined",
                "id" => participant_id,
                "participants" => _other_participants,
                "room" => _room_id
              },
              "plugin" => "janus.plugin.audiobridge"
            },
            "sender" => ^handle_id,
            "session_id" => ^session_id
          } ->
            send(Map.get(state, :pid), {:gimme_offer, "gimme_offer"})

            state
            |> Map.put(:txs, txs)
            |> Map.put(:participant_id, participant_id)
        end

      {:trickle, txs} ->
        %{session_id: session_id} = state
        %{"janus" => "ack", "session_id" => ^session_id} = msg
        Map.put(state, :txs, txs)

      {nil, _txs} ->
        %{session_id: session_id, handle_id: handle_id} = state

        case msg do
          %{
            "janus" => "event",
            "jsep" =>
              %{
                "sdp" => _sdp,
                "type" => "answer"
              } = answer,
            "plugindata" => %{
              "data" => %{"audiobridge" => "event", "result" => "ok"},
              "plugin" => "janus.plugin.audiobridge"
            },
            "sender" => ^handle_id,
            "session_id" => ^session_id
            # TODO why is transaction not found?
            # "transaction" => "FB0UysgRy+0"
          } ->
            send(Map.get(state, :pid), {:answer, answer})

          _other ->
            IO.inspect(msg, label: "unexpected socket tx message")
        end

        state
    end
  end

  defp handle_janus_msg(msg, state) do
    IO.inspect(msg, label: "unexpected socket message")

    state
  end
end
