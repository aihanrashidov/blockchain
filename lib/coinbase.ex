defmodule Coinbase do

  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    state = %{total: 1000, current_reward: 50, blocks: 0}
    {:ok, state}
  end

  def get_total_value() do
    GenServer.call(__MODULE__, {:get_total_value})
  end

  def update(amount) do
    GenServer.call(__MODULE__, {:update, amount})
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
