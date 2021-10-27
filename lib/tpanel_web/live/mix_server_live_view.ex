defmodule TpanelWeb.MixServerLiveView do
  use TpanelWeb, :live_view

  defmodule Message do
    defstruct mid: 0, styles: "", text: "", hidden: false
  end

  def mount(_params, %{"test_mix_id" => mix_id}, socket) do
    TpanelWeb.Endpoint.subscribe("mixserver_#{mix_id}")
    {:ok, 
     assign(socket, clear: 0, mix_id: mix_id, msg_id: 1, mixserver: [], messages: [])
     |> scan_mixserver(),
     temporary_assigns: [messages: []]
    }
  end

  def scan_mixserver(socket) do
    assign(socket, mixserver: Tpanel.MixSupervisor.get_mixserver(socket.assigns.mix_id))
  end

  def get_mixserver(socket) do
    assign(socket, mixserver: Tpanel.MixSupervisor.get_mixserver(socket.assigns.mix_id, start: true))
  end  

  def handle_event("start_mixserver", _stuff, socket) do
    {:noreply, assign(socket, mixserver: get_mixserver(socket))}
  end

  def handle_event("update_mixserver", _stuff, socket) do
    socket = get_mixserver(socket)
    GenServer.cast(socket.assigns.mixserver, :fetch)
    {:noreply, socket}
  end

  def handle_event("launch_mix", _stuff, socket) do
    socket = get_mixserver(socket)
    GenServer.cast(socket.assigns.mixserver, :mix)
    {:noreply, socket}
  end

  def handle_event("launch_build", _stuff, socket) do
    socket = get_mixserver(socket)
    GenServer.cast(socket.assigns.mixserver, :build)
    {:noreply, socket}
  end

  def handle_event("clear_view", _stuff, socket) do
    {:noreply, assign(socket, clear: socket.assigns.clear + 1)}
  end

  def handle_info(%{event: event, payload: payload}, socket) do
    if event == "reloaded" do
      {:noreply, scan_mixserver(socket)}
    else
      {:noreply, handle_payload(event, payload, socket)}
    end
  end

  def handle_payload(event, %{} = payload, socket) do
    msg_id = socket.assigns.msg_id + 1
    message = %Message{generate_message(event, payload) | mid: "msg-#{msg_id}"}
    assign(socket, msg_id: msg_id, messages: [message | socket.assigns.messages])
  end

  def generate_message("output", %{stream: "stdout"} = payload) do
    %Message{styles: "text-white", text: payload.msg}
  end
  
  def generate_message("output", %{stream: "stderr"} = payload) do
    %Message{styles: "text-yellow-400", text: payload.msg}
  end

  def generate_message("exec", %{} = payload) do
    %Message{styles: "text-green-500", text: "#{payload.directory}> #{Enum.join(payload.command, " ")}"}
  end

  def generate_message("status", %{status: 0}) do
    %Message{styles: "text-gray-500", text: "Task exited successfully", hidden: true}
  end

  def generate_message("status", %{} = payload) do
    %Message{styles: "text-yellow-600", text: "Task returned exit code #{payload.status}"}
  end

  def generate_message("info", %{} = payload) do
    %Message{styles: "text-blue-600", text: "= #{payload.msg}"}
  end

  def generate_message("error", %{} = payload) do
    %Message{styles: "text-red-500 font-bold", text: payload.msg}
  end

  def generate_message("fatal", %{} = payload) do
    %Message{styles: "text-red-800 font-bold py-1", text: "!!! #{payload.msg}"}
  end

  def generate_messages(event, _payload) do
    %Message{styles: "text-gray-300", text: "Got unhandled event: #{event}"}
  end
end
