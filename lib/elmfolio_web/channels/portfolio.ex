defmodule ElmfolioWeb.PortfolioChannel do
  use Phoenix.Channel

  @channel_name "portfolio"

  def join(@channel_name <> ":lobby", _message, socket) do
    {:ok, socket}
  end

  def handle_in("get_items", _payload, socket) do
    Elmfolio.Portfolio.Api.get() |> respond(socket)
  end

  def handle_in("like_item", %{ "categoryId" => categoryId, "itemId" => itemId }, socket) do
    Elmfolio.Portfolio.Api.get() |> respond(socket)
  end

  defp respond({:ok, items}, socket) do
    push(socket, "get_items", %{code: 200, response: items})
    {:noreply, socket}
  end

  defp respond({_, items}, socket) do
    push(socket, "get_items", %{code: 500, response: items})
    {:noreply, socket}
  end
end
