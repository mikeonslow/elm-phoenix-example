defmodule Portfolio.Server do
  use GenServer, Elmfolio

  # Portfolio.Server.list

  def start_link(_args) do
    GenServer.start_link(__MODULE__, struct(Portfolio), name: __MODULE__)
  end

  # Callbacks

  @impl true
  def init(portfolio) do
    {:ok, portfolio}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:push, item}, state) do
    {:noreply, [item | state]}
  end

  def push do
    __MODULE__
    |> GenServer.cast({:push, "item"})
  end

  def list do
    __MODULE__
    |> GenServer.call(:list)
  end
end
