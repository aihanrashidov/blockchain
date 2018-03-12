defmodule Blockchain do
use GenServer

def start_link do
  GenServer.start_link(__MODULE__, [], name: __MODULE__)
  pool_pid = Pool.start_link
end

def init(_) do
  first_block = %{
    head: %{
      hash: "6B86B273FF34FCE19D6B804EFF5A3F5747ADA4EAA22F1D49C01E52DDB7875B4B",
      previous_hash: 0,
      difficulty_target: 0,
      nonce: 0
    },
    transaction_list: [
      %{
        from: nil,
        to: nil,
        amount: 0,
        sig: nil
      }
    ]
  }

  state = [first_block]
  {:ok, state}
end

def show_blocks() do
  GenServer.call(__MODULE__, (:show_blocks))
end

def make_transaction(from, to, amount) do
  transaction = Map.from_struct(%TransactionStructure{from: from, to: to, amount: amount})
  Pool.add_to_pool(transaction)
end

defp add_new_block_to_list(new_block) do
  GenServer.call(__MODULE__, {:add_new_block_to_list, new_block})
end

def handle_call((:show_blocks), _from, state) do
  {:reply, state, state}
end

def handle_call({add_new_block_to_list, new_block}, _from, state) do
  state = [state | new_block]
  {:ok, state, state}
end

end
