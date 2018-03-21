defmodule Coinbase do

  @doc """
  This is the Coinbase module. Used for reward calculations and checking how
  much is the total value of tokens left.
  """

  use GenServer

  ## Client API

  @doc """
  Starts the GenServer.
  """

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Returns the state (shows how many coins have left, how many blocks are mined
  and what is the current reward value).

  ##Parameters:
  No parameters.

  ##Examples:

    iex> Coinbase.get_total_value()
    %{blocks: 5, current_reward: 25.0, total: 750}

  """

  def get_total_value() do
    GenServer.call(__MODULE__, {:get_total_value})
  end

  @doc """
  Updates the state using a simple algorithm to calculate the current reward
  value each time a new block is mined.

  ##Parameters:
  - amount: Integer (the current_reward).

  ##Examples:
  No Examples.

  """

  def update(amount) do
    GenServer.call(__MODULE__, {:update, amount})
  end

  ## Server Callbacks

  def init(_) do
    state = %{total: 1000, current_reward: 10, blocks: 0}
    {:ok, state}
  end

  def handle_call({:get_total_value}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:update, amount}, _from, state) do
    new_total = state.total - amount
    new_blocks = state.blocks + 1
    if rem(new_blocks, 5) == 0 do
      new_reward = state.current_reward / 2
    else
      new_reward = state.current_reward
    end

    new_state = %{state | total: new_total, current_reward: new_reward, blocks: new_blocks}
    {:reply, state, new_state}
  end

end
