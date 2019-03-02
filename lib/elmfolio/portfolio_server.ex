defmodule Elmfolio.Portfolio.Server do
  use GenServer

  # Elmfolio.Portfolio.Server.get

  def start_link(_args) do
    GenServer.start_link(__MODULE__, struct(Elmfolio.Portfolio), name: __MODULE__)
  end

  # Callbacks

  @impl true
  def init(portfolio) do
    Process.send_after(
      self(),
      :hydrate,
      0
    )

    {:ok, portfolio}
  end

  @impl true
  def handle_info(:hydrate, _state) do
    {:noreply, hydrate_portfolio}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def get do
    __MODULE__
    |> GenServer.call(:get)
  end

  defp hydrate_portfolio do
    Elmfolio.Portfolio.Api.get() |> hydrate_portfolio
  end

  defp hydrate_portfolio({200, %{"categories" => _categories, "items" => _items} = portfolio}) do
    {200, portfolio}
  end

  defp hydrate_portfolio(_data) do
    {500, struct(Elmfolio.Portfolio)}
  end
end
