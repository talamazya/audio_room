defmodule JanusEx.JanusChannelTest do
  use JanusEx.RoomCase
  use Web.ChannelCase

  alias Web.RoomChannel
  alias Web.UserSocket
  alias JanusEx.JanusChannel
  alias JanusEx.Room

  setup do
    {:ok, _, socket} =
      UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(RoomChannel, "room:abc")

    {:ok, pid: socket.assigns.janus_channel_pid}
  end

  describe "process handle webrtc connection" do
    test "when process_session", %{pid: _pid} do
      msg = %{
        "data" => %{"id" => 5_730_850_383_511_239},
        "janus" => "success",
        "transaction" => "DCQQkOdefuI"
      }

      txs = %{}
      state = %{pid: "aPid", room_name: "abc", txs: %{"DCQQkOdefuI" => :session}}

      new_state = JanusChannel.process_session(state, txs, msg)

      assert Map.get(new_state, :pid) == "aPid"
      assert Map.get(new_state, :room_name) == "abc"
      assert Map.get(new_state, :session_id) == 5_730_850_383_511_239
      assert !is_nil(Enum.find(Map.get(new_state, :txs), fn {_k, v} -> v == :handle end))
    end

    test "when process_handle for new room" do
      msg = %{
        "data" => %{"id" => 246_420_810_263_827},
        "janus" => "success",
        "session_id" => 2_339_498_122_570_977,
        "transaction" => "SKtundPiu/o"
      }

      txs = %{}

      state = %{
        pid: :a_pid,
        room_name: "abc",
        session_id: 2_339_498_122_570_977,
        txs: %{"SKtundPiu/o" => :handle}
      }

      new_state = JanusChannel.process_handle(state, txs, msg)

      assert Map.get(new_state, :pid) == :a_pid
      assert Map.get(new_state, :room_name) == "abc"
      assert Map.get(new_state, :session_id) == 2_339_498_122_570_977

      assert !is_nil(
               Enum.find(Map.get(new_state, :txs), fn {k, v} ->
                 (v == :create or v == :join) and k != "SKtundPiu/o"
               end)
             )
    end

    test "when process_create" do
      msg = %{
        "janus" => "success",
        "plugindata" => %{
          "data" => %{
            "audiobridge" => "created",
            "permanent" => false,
            "room" => 132_321_803
          },
          "plugin" => "janus.plugin.audiobridge"
        },
        "sender" => 8_075_556_649_374_213,
        "session_id" => 8_382_113_743_998_130,
        "transaction" => "p56gCt7hHwI"
      }

      txs = %{}

      state = %{
        handle_id: 8_075_556_649_374_213,
        pid: :a_pid,
        room_name: "abc",
        session_id: 8_382_113_743_998_130,
        txs: %{"p56gCt7hHwI" => :create}
      }

      new_state = JanusChannel.process_create(state, txs, msg)

      assert Map.get(new_state, :pid) == :a_pid
      assert Map.get(new_state, :room_name) == "abc"
      assert Map.get(new_state, :session_id) == 8_382_113_743_998_130
      assert Map.get(new_state, :handle_id) == 8_075_556_649_374_213

      assert !is_nil(
               Enum.find(Map.get(new_state, :txs), fn {k, v} ->
                 v == :join and k != "p56gCt7hHwI"
               end)
             )
    end

    test "when process_join", %{pid: pid} do
      room_name = "abc"
      room_id = 132_321_803
      Room.create(room_name, room_id)

      msg = %{
        "janus" => "event",
        "plugindata" => %{
          "data" => %{
            "audiobridge" => "joined",
            "id" => 818_118_250_583_754,
            "participants" => [],
            "room" => room_id
          },
          "plugin" => "janus.plugin.audiobridge"
        },
        "sender" => 3_267_874_789_631_146,
        "session_id" => 3_129_962_664_392_735,
        "transaction" => "phwV1BdFux0"
      }

      txs = %{}

      state = %{
        handle_id: 3_267_874_789_631_146,
        pid: pid,
        room_name: room_name,
        session_id: 3_129_962_664_392_735,
        txs: %{"phwV1BdFux0" => :join}
      }

      new_state = JanusChannel.process_join(state, txs, msg)

      assert Map.get(new_state, :room_name) == room_name
      assert Map.get(new_state, :session_id) == 3_129_962_664_392_735
      assert Map.get(new_state, :handle_id) == 3_267_874_789_631_146
      assert !is_nil(Map.get(new_state, :participant_id))
    end
  end
end
