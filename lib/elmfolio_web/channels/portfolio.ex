defmodule ElmfolioWeb.PortfolioChannel do
  use Phoenix.Channel

  @channel_name "portfolio"

  def join(@channel_name <> ":lobby", _message, socket) do
    {:ok, socket}
  end

  def handle_in("get_items", _payload, socket) do
    Elmfolio.Portfolio.Server.get() |> respond(socket)
  end

  def handle_in("like_item", %{"categoryId" => _categoryId, "itemId" => _itemId} = items, socket) do
    push(socket, "like_item", %{code: 200, response: items})
    {:noreply, socket}
  end

  def handle_in("unlike_item", %{"categoryId" => _categoryId, "itemId" => _itemId}, _socket) do
    "unlike_item"
  end

  defp respond({200, items}, socket) do
    push(socket, "get_items", %{code: 200, response: items})
    {:noreply, socket}
  end

  defp respond({_, items}, socket) do
    push(socket, "get_items", %{code: 500, response: items})
    {:noreply, socket}
  end
end
