defmodule Blockchain do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
    Pool.start_link()
    Accounts.start_link()
    Coinbase.start_link()
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
    all_acc_public_keys = for n <- accounts, do: n.public_key

    sender_key = for n <- all_acc_public_keys, n == from, do: 1
    reciever_key = for n <- all_acc_public_keys, n == to, do: 1

    if sender_key == [1] && reciever_key == [1] do

    [sender_account] = for n <- accounts, n.public_key == from, do: n

    sender_priv_key = sender_account.private_key
    decoded_priv_key = Base.decode16(sender_priv_key) |> elem(1)

    transaction_data = "#{from}#{to}#{amount}"
    signature = :crypto.sign(:ecdsa, :sha256, transaction_data, [decoded_priv_key, :secp256k1]) |> Base.encode16()
    transaction = Map.from_struct(%TransactionStructure{from: from, to: to, amount: amount, sig: signature})
    Pool.add_to_pool(transaction)
    else
      "Invalid sender or reciever public key (address)."
    end
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
        Accounts.update_account_balance_plus(acc, current_reward)
        Coinbase.update(current_reward)
        all_transactions = Pool.take_from_pool()
        verified_transactions = verify_transactions(all_transactions, [])
        tx_merkle_tree_hash = tx_merkle_tree_hash_calculation(verified_transactions) |> Base.encode16
        acc_merkle_tree_hash = acc_merkle_tree_hash_calculation(Accounts.show_accounts) |> Base.encode16
        new_block = mine(state, nonce, difficulty_target, tx_merkle_tree_hash, acc_merkle_tree_hash)
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

  defp acc_merkle_tree_hash_calculation(accounts) do
    merkle_tree = :gb_merkle_trees.empty()

    if accounts == [] do
      <<0::256>>
    else
      account_hashes = calc_acc_hash(accounts, [])
      list_length = Kernel.length(account_hashes)

      if rem(list_length, 2) == 1 do
        last_account_hash = Enum.at(account_hashes, -1)
        new_account_hashes = account_hashes ++ [last_account_hash]
        :gb_merkle_trees.root_hash(add_to_tree(new_account_hashes, merkle_tree))
      else
        :gb_merkle_trees.root_hash(add_to_tree(account_hashes, merkle_tree))
      end
    end
  end

  defp tx_merkle_tree_hash_calculation(verified_transactions) do
    merkle_tree = :gb_merkle_trees.empty()

    if verified_transactions == [] do
      <<0::256>>
    else
      transaction_hashes = calc_tx_hash(verified_transactions, [])
      list_length = Kernel.length(transaction_hashes)

      if rem(list_length, 2) == 1 do
        last_transaction_hash = Enum.at(transaction_hashes, -1)
        new_transaction_hashes = transaction_hashes ++ [last_transaction_hash]
        :gb_merkle_trees.root_hash(add_to_tree(new_transaction_hashes, merkle_tree))
      else
        :gb_merkle_trees.root_hash(add_to_tree(transaction_hashes, merkle_tree))
      end
    end
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

  defp mine(state, nonce, difficulty_target, tx_merkle_tree_hash, acc_merkle_tree_hash) do
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
        merkle_root_hash: tx_merkle_tree_hash,
        chain_state_hash: acc_merkle_tree_hash
      }
    })

    hash_to_check = String.slice(new_block.head.hash, 0..new_block.head.difficulty_target-1)
    difficulty_string = difficulty_to_string(new_block.head.difficulty_target)

    if hash_to_check == difficulty_string do
      new_block
    else
      new_nonce = nonce + 1
      mine(state, new_nonce, difficulty_target, tx_merkle_tree_hash, acc_merkle_tree_hash)
    end
  end

  defp difficulty_to_string(difficulty_target) do
    difficulty_target_zeroes_list = for n <- 0..difficulty_target-1, do: "0"
    difficulty_target_zeroes_string = List.to_string(difficulty_target_zeroes_list)
    difficulty_target_zeroes_string
  end

  def verify_transactions([], new_list_of_valid_transactions) do
    new_list_of_valid_transactions
  end

  def verify_transactions([head | tail], list_of_valid_transactions) do
    accounts_list = Accounts.show_accounts()
    [sender_account] = for n <- accounts_list, n.public_key == head.from, do: n
    [receiver_account] = for n <- accounts_list, n.public_key == head.to, do: n

    transaction_data = "#{head.from}#{head.to}#{head.amount}"

    decoded_public_key = Base.decode16(sender_account.public_key) |> elem(1)
    decoded_signature = Base.decode16(head.sig) |> elem(1)
    validate_signature = :crypto.verify(:ecdsa, :sha256, transaction_data, decoded_signature, [decoded_public_key, :secp256k1])

    if sender_account.balance >= head.amount && validate_signature == true do
      list_of_valid_transactions = list_of_valid_transactions ++ [head]
      Accounts.update_account_balance_plus(receiver_account, head.amount)
      Accounts.update_account_balance_minus(sender_account, head.amount)
      verify_transactions(tail, list_of_valid_transactions)
    else
      verify_transactions(tail, list_of_valid_transactions)
    end
  end

  defp calc_tx_hash([], list) do
    list
  end

  defp calc_tx_hash([head | tail], list) do
    transaction_data = "#{head.from}#{head.to}#{head.amount}#{head.sig}"
    hash = {:crypto.hash(:sha256, transaction_data), transaction_data}
    list = list ++ [hash]
    calc_tx_hash(tail, list)
  end

  defp calc_acc_hash([], list) do
    list
  end

  defp calc_acc_hash([head | tail], list) do
    account_data = "#{head.name}#{head.private_key}#{head.public_key}#{head.ballance}"
    hash = {:crypto.hash(:sha256, account_data), account_data}
    list = list ++ [hash]
    calc_acc_hash(tail, list)
  end

  defp add_to_tree([], merkle_tree) do
    merkle_tree
  end

  defp add_to_tree([head | tail], merkle_tree) do
    merkle_tree = :gb_merkle_trees.enter(elem(head, 0), elem(head, 1), merkle_tree)
    add_to_tree(tail, merkle_tree)
  end

@doc """
  Transaction hashes pair calculations.

  def calc_pairs([], list) do
    list_length = Kernel.length(list)

    if list_length == 1 do
      list
    else
      if rem(list_length, 2) == 1 do
        last_transaction_hash = Enum.at(list, -1)
        new_transaction_hashes = list ++ [last_transaction_hash]
        calc_pairs(new_transaction_hashes, [])
      else
        calc_pairs(list, [])
      end
    end
  end

  def calc_pairs([h1, h2 | tail], list) do
    list = list ++ [:crypto.hash(:sha256, "{h1}{h2}")]
    calc_pairs(tail, list)
  end

"""

end
