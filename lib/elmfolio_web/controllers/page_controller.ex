defmodule ElmfolioWeb.PageController do
  use ElmfolioWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
