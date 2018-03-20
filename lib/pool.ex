defmodule Pool do

  @doc """
  This is the Pool module. New transactions are kept here until a new
  block is mined.
  """

  use GenServer

  ## Client API

  @doc """
  Starts the GenServer.
  """

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_to_pool(transaction) do
    GenServer.call(__MODULE__, {:add_to_pool, transaction})
  end

  def take_from_pool() do
    GenServer.call(__MODULE__, {:take_from_pool})
  end

  def show_transactions_pool() do
    GenServer.call(__MODULE__, {:show_transactions_pool})
  end

  ## Server Callbacks

  def init(_) do
    state = []
    {:ok, state}
  end

  def handle_call({:add_to_pool, transaction}, _from, state) do
    new_state = state ++ [transaction]
    {:reply, "A new transaction has been added to the pool.", new_state}
  end

  def handle_call({:take_from_pool}, _from, state) do
    get_state = state
    new_state = []
    {:reply, take_from_pool(get_state), new_state}
  end

  def handle_call({:show_transactions_pool}, _from, state) do
    {:reply, state, state}
  end

  defp take_from_pool(state) do
    state
  end

end
