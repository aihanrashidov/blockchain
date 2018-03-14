defmodule Blockchain do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
    pool_pid = Pool.start_link()
    accounts_pid = Accounts.start_link()
  end

  def init(_) do
    first_block = %{
      head: %{
        index: 0,
        hash: "5FECEB66FFC86F38D952786C6D696C79C2DBC239DD4E91B46729D73A27FB57E9",
        previous_hash: 0,
        timestamp: DateTime.utc_now() |> DateTime.to_string(),
        difficulty_target: 0,
        nonce: 0,
        merkle_root_hash: nil,
        chain_state_hash: nil
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
    GenServer.call(__MODULE__, {:show_blocks})
  end

  def make_transaction(from, to, amount) do
    transaction = Map.from_struct(%TransactionStructure{from: from, to: to, amount: amount})
    Pool.add_to_pool(transaction)
    #update_current_block(transaction)
  end

  #def update_current_block(transaction) do
  #  GenServer.call(__MODULE__, {:update_current_block, transaction})
  #end

  def create_new_block() do
    GenServer.call(__MODULE__, {:create_new_block})
  end

  def handle_call({:show_blocks}, _from, state) do
    {:reply, state, state}
  end

  #def handle_call({:update_current_block, transaction}, _from, state) do
  #  current_block = Enum.at(state, -1)
  #  current_block = %{current_block | transaction_list: current_block.transaction_list ++ [transaction]}
  #  new_state = List.replace_at(state, -1, current_block)
  #  {:reply, "Transactions updated!", new_state}
  #end

  def handle_call({:create_new_block}, _from, state) do
    block_s = %BlockStructure{}
    nonce = block_s.head.nonce
    difficulty_target = 4
    all_transactions = Pool.take_from_pool()
    new_block = mine(state, nonce, difficulty_target)
    new_block = %{new_block | transaction_list: all_transactions}
    new_state = state ++ [new_block]

    {:reply, "New block was created and added to the chain.", new_state}
  end

  defp mine(state, nonce, difficulty_target) do
    old_block = Enum.at(state, -1)
    new_timestamp = DateTime.utc_now() |> DateTime.to_string()

    new_block = Map.from_struct(%BlockStructure{
      head: %{
        index: old_block.head.index + 1,
        hash: (:crypto.hash(:sha256, "#{old_block.head.index + 1}#{old_block.head.hash}#{difficulty_target}#{nonce}#{new_timestamp}") |> Base.encode16),
        previous_hash: old_block.head.hash,
        difficulty_target: difficulty_target,
        nonce: nonce,
        timestamp: new_timestamp,
        merkle_root_hash: nil,
        chain_state_hash: nil
      }
    })

    hash_to_check = String.slice(new_block.head.hash, 0..new_block.head.difficulty_target-1)
    difficulty_string = difficulty_to_string(new_block.head.difficulty_target)

    if hash_to_check == difficulty_string do
      new_block
    else
      new_nonce = nonce + 1
      mine(state, new_nonce, difficulty_target)
    end
  end

  defp difficulty_to_string(difficulty_target) do
    difficulty_target_zeroes_list = for n <- 0..difficulty_target-1, do: "0"
    difficulty_target_zeroes_string = List.to_string(difficulty_target_zeroes_list)
    difficulty_target_zeroes_string
  end

end
