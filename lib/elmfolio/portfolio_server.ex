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
    {:noreply, hydrate_portfolio()}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(
        {:like_item, %{"categoryId" => categoryId, "itemId" => itemId} = itemAndCategoryIds},
        _from,
        state
      ) do
    state |> like_item(itemAndCategoryIds)
    {:reply, state, state}
  end

  @impl true
  def handle_call({:unlike_item, %{"categoryId" => categoryId, "itemId" => itemId}}, _from, state) do
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

  defp like_item(
         {200, portfolio},
         %{"categoryId" => categoryId, "itemId" => itemId} = categoryAndItemIds
       ) do
    %{"categories" => categories, "items" => items} = portfolio

    updatedItems = items |> Enum.map(&update_item_likes(&1, categoryAndItemIds)) |> IO.inspect()

    {200, %{portfolio | items: updatedItems}}
  end

  defp like_item({500, portfolio} = state, _categoryAndItemId) do
    state
  end

  defp update_item_likes(
         %{"id" => itemId, "categoryId" => categoryId} = item,
         %{"categoryId" => likeCategoryId, "itemId" => likeItemId}
       )
       when likeCategoryId == categoryId and likeItemId == itemId do
    # newLikes = item.likes + 1
    item |> IO.inspect()
    Map.put(item, :likes, 2)
  end

  defp update_item_likes({_args, item}) do
    item
  end

  defp unlike_item({200, portfolio}, %{"categoryId" => categoryId, "itemId" => itemId}) do
    state
  end

  defp unlike_item({500, portfolio} = state, _categoryAndItemId) do
    state
  end
end

# Elmfolio.Portfolio.Server |> GenServer.call({:like_item, %{"categoryId" => 1, "itemId" => 1}})
# Elmfolio.Portfolio.Server.get()
