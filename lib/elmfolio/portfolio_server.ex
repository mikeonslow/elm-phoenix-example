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
    updatedState = state |> like_item(itemAndCategoryIds)
    {:reply, updatedState, updatedState}
  end

  @impl true
  def handle_call(
        {:unlike_item, %{"categoryId" => categoryId, "itemId" => itemId} = itemAndCategoryIds},
        _from,
        state
      ) do
    updatedState = state |> unlike_item(itemAndCategoryIds)
    {:reply, updatedState, updatedState}
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
         {200, %{"categories" => categories, "items" => items} = portfolio},
         %{"categoryId" => categoryId, "itemId" => itemId} = categoryAndItemIds
       ) do
    {200,
     %{
       portfolio
       | "items" =>
           items
           |> Enum.map(&increment_item_likes(&1, categoryAndItemIds))
     }}
  end

  defp like_item({500, portfolio} = state, _categoryAndItemId) do
    state
  end

  defp increment_item_likes(
         %{"id" => itemId, "categoryId" => categoryId, "likes" => currentLikes} = item,
         %{"categoryId" => likeCategoryId, "itemId" => likeItemId}
       )
       when likeCategoryId == categoryId and likeItemId == itemId do
    %{item | "likes" => currentLikes + 1} |> IO.inspect()
  end

  defp increment_item_likes(item, _categoryAndItemId) do
    item
  end

  defp decrement_item_likes(
         %{"id" => itemId, "categoryId" => categoryId, "likes" => currentLikes} = item,
         %{"categoryId" => likeCategoryId, "itemId" => likeItemId}
       )
       when likeCategoryId == categoryId and likeItemId == itemId and currentLikes > 0 do
    %{item | "likes" => currentLikes - 1} |> IO.inspect()
  end

  defp decrement_item_likes(item, _categoryAndItemId) do
    item
  end

  defp unlike_item(
         {200, %{"categories" => categories, "items" => items} = portfolio},
         %{"categoryId" => categoryId, "itemId" => itemId} = categoryAndItemIds
       ) do
    {200,
     %{
       portfolio
       | "items" =>
           items
           |> Enum.map(&decrement_item_likes(&1, categoryAndItemIds))
     }}
  end

  defp unlike_item({500, portfolio} = state, _categoryAndItemId) do
    state
  end
end

# Elmfolio.Portfolio.Server |> GenServer.call({:like_item, %{"categoryId" => 1, "itemId" => 1}})
# Elmfolio.Portfolio.Server |> GenServer.call({:unlike_item, %{"categoryId" => 1, "itemId" => 1}})
# Elmfolio.Portfolio.Server.get()
