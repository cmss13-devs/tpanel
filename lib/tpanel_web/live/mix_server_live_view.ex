defmodule TpanelWeb.MixServerLiveView do
  use TpanelWeb, :live_view

  defmodule Message do
    defstruct mid: 0, styles: "", text: "", hidden: false
  end

  def mount(_params, %{"test_mix_id" => mix_id}, socket) do
    TpanelWeb.Endpoint.subscribe("mixserver_#{mix_id}")
    {:ok, assign(socket, mid: 1, messages: [], temporary_assigns: [messages: []])}
  end

  def handle_info(%{event: event, payload: payload}, socket) do
    {:noreply, handle_payload(event, payload, socket)}
  end

  def handle_payload(event, %{} = payload, socket) do
    mid = socket.assigns.mid + 1
    message = %Message{generate_message(event, payload) | mid: "msg-#{mid}"}
    assign(socket, mid: mid, messages: [message | socket.assigns.messages])
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
