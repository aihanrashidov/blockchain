defmodule Pool do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    state = []
    {:ok, state}
  end

  def add_to_pool(transaction) do
    GenServer.call(__MODULE__, {:add_to_pool, transaction})
  end

  def show_transactions_pool() do
    GenServer.call(__MODULE__, {:show_transactions_pool})
  end

  def handle_call({:add_to_pool, transaction}, _from, state) do
    new_state = state ++ [transaction]
    {:reply, "A new transaction has been added to the pool.", new_state}
  end

  def handle_call({:show_transactions_pool}, _from, state) do
    {:reply, state, state}
  end
end
