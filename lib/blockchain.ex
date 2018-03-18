defmodule Blockchain do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
    pool_pid = Pool.start_link()
    accounts_pid = Accounts.start_link()
    coinbase_pid = Coinbase.start_link()
  end

  def init(_) do
    genesis_block = %{
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

    state = [genesis_block]
    {:ok, state}
  end

  def show_blocks() do
    GenServer.call(__MODULE__, {:show_blocks})
  end

  def make_transaction(from, to, amount) do
    accounts = Accounts.show_accounts()
    [sender_account] = for n <- accounts, n.public_key == from, do: n

    sender_priv_key = sender_account.private_key
    decoded_priv_key = Base.decode16(sender_priv_key) |> elem(1)

    transaction_data = "#{from}#{to}#{amount}"
    signature = :crypto.sign(:ecdsa, :sha256, transaction_data, [decoded_priv_key, :secp256k1]) |> Base.encode16()
    transaction = Map.from_struct(%TransactionStructure{from: from, to: to, amount: amount, sig: signature})
    Pool.add_to_pool(transaction)
  end

  def create_block(account_name) do
    coinbase = Coinbase.get_total_value()
    total_reward_value = coinbase.total
    current_reward = coinbase.current_reward

    if total_reward_value > 0 do

      accounts = Accounts.show_accounts()
      list_of_account_names = for n <- accounts, do: Map.fetch!(n, :name)

      if Enum.member?(list_of_account_names, account_name) == true do
        [acc_pub_key] = for n <- accounts, account_name == n.name, do: n.public_key
        [acc] = for n <- accounts, account_name == n.name, do: n
        state = show_blocks()
        block_s = %BlockStructure{}
        nonce = block_s.head.nonce
        difficulty_target = 3
        new_block = mine(state, nonce, difficulty_target)
        Accounts.update_account_ballance_plus(acc, current_reward)
        Coinbase.update(current_reward)
        all_transactions = Pool.take_from_pool()
        verified_transactions = verify_transactions(all_transactions, accounts, [])
        add_new_block(new_block, verified_transactions)
        generate_transaction("-", acc_pub_key, current_reward)
      else
        "There is no such account!"
      end
    else
      "No more blocks to mine!"
    end
  end

  def add_new_block(new_block, verified_transactions) do
    GenServer.call(__MODULE__, {:add_new_block, new_block, verified_transactions})
  end

  def generate_transaction(from, to, amount) do
    transaction = Map.from_struct(%TransactionStructure{from: from, to: to, amount: amount, sig: "-"})
    update_new_block(transaction)
  end

  def update_new_block(transaction) do
    GenServer.call(__MODULE__, {:update_new_block, transaction})
  end

  def handle_call({:show_blocks}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:update_new_block, transaction}, _from, state) do
    current_block = Enum.at(state, -1)
    current_block = %{current_block | transaction_list: current_block.transaction_list ++ [transaction]}
    new_state = List.replace_at(state, -1, current_block)
    {:reply, "New block was created and added to the chain.", new_state}
  end

  def handle_call({:add_new_block, new_block, verified_transactions}, _from, state) do
    new_block = %{new_block | transaction_list: verified_transactions}
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

  defp verify_transactions(all_transactions, [], new_list_of_valid_transactions) do
    new_list_of_valid_transactions
  end

  defp verify_transactions(all_transactions, [head | tail], list_of_valid_transactions) do
    transactions_from_each_acc = for n <- all_transactions, head.public_key == n.from, do: n
    current_account_ballance = head.ballance
    current_account = head
    valid_transactions = check(transactions_from_each_acc, current_account_ballance, [], current_account)
    new_list_of_valid_transactions = list_of_valid_transactions ++ valid_transactions
    verify_transactions(all_transactions, tail, new_list_of_valid_transactions)
  end

  defp check([], current_account_ballance, transactions, current_account) do
    transactions
  end

  defp check([head | tail], current_account_ballance, transactions, current_account) do
    transaction_data = "#{head.from}#{head.to}#{head.amount}"
    decoded_public_key = Base.decode16(current_account.public_key) |> elem(1)
    decoded_signature = Base.decode16(head.sig) |> elem(1)
    validate_signature = :crypto.verify(:ecdsa, :sha256, transaction_data, decoded_signature, [decoded_public_key, :secp256k1])

    if head.amount <= current_account_ballance && validate_signature == true do
      transactions = transactions ++ [head]

      accounts_list = Accounts.show_accounts()

      [receiving_account] = for n <- accounts_list, n.public_key == head.to, do: n
      [sending_account] = for n <- accounts_list, n.public_key == head.from, do: n
      Accounts.update_account_ballance_plus(receiving_account, head.amount)
      Accounts.update_account_ballance_minus(sending_account, head.amount)

      accounts_list = Accounts.show_accounts()

      [sending_account] = for n <- accounts_list, n.public_key == head.from, do: n
      new_account_ballance = sending_account.ballance

      check(tail, new_account_ballance, transactions, sending_account)
    else
      check(tail, current_account_ballance, transactions, current_account)
    end
  end

end
