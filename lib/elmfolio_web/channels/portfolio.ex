defmodule ElmfolioWeb.PortfolioChannel do
  use Phoenix.Channel

  @channel_name "portfolio"

  def join(@channel_name <> ":lobby", _message, socket) do
    {:ok, socket}
  end

  def handle_in("get_items", _payload, socket) do
    {:reply, Elmfolio.Portfolio.list(), socket}
  end
end
