defmodule Accounts do

  @doc """
  This is the Accounts module. Used for keeping the accounts information and
  using it in the other modules.
  """

  use GenServer

  ## Client API

  @doc """
  Starts the GenServer.
  """

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Returns the state (shows the accounts list which is the state).

  ##Parameters:
  No parameters.

  ##Examples:

    iex> Accounts.show_accounts()
    [
      %{
        balance: 100,
        name: "Ayhan",
        private_key: "F7E8E57DA3D522082BBEADB7FDECE9BA",
        public_key: "045443F9C80243BC8A1EEFBA5F024076E499A103C92CB53B544C3E7D8161E1320550E0C0DB9A2DE1F6B77D4E18EF349EC48BE5D4C49AEDB31431DBE71FA8CEBBC4"
      }
    ]

  """

  def show_accounts() do
    GenServer.call(__MODULE__, {:show_accounts})
  end

  @doc """
  Creates an account and adds it to the state (list of accounts).

  ##Parameters:
  - name: String specifying the name of the account.
  - tokens: Integer used for the initial account balance. Default is 0.

  ##Examples:

    iex> Accounts.create_account("Ayhan", 100)
    "New account with a balance of 100 tokens has been created!"

  """

  def create_account(name, tokens \\ 0) do
    GenServer.call(__MODULE__, {:create_account, name, tokens})
  end

  @doc """
  These two functions update the specified account's balance with X
  tokens. One of them adds and the other one substracts tokens from the account
  balance.

  ##Parameters:
  - acc: Map containing account keys and values.
  - tokens: Integer used to update the account's balance.

  ##Examples:
  No examples.

  """

  def update_account_balance_plus(acc, tokens) do
    GenServer.call(__MODULE__, {:update_account_balance_plus, acc, tokens})
  end

  def update_account_balance_minus(acc, tokens) do
    GenServer.call(__MODULE__, {:update_account_balance_minus, acc, tokens})
  end

  ## Server Callbacks

  def init(_)do
    state = []
    {:ok, state}
  end

  def handle_call({:show_accounts}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:create_account, name, tokens}, _from, state) do
    {pr_key, pu_key} = Keys.create_keys()

    acc_details = %{
      name: name,
      private_key: pr_key,
      public_key: pu_key,
      balance: tokens
    }
    new_state = state ++ [acc_details]
    {:reply, "New account with a balance of #{tokens} tokens has been created!", new_state}
  end

  def handle_call({:update_account_balance_plus, acc, tokens}, _from, state) do
    state = state -- [acc]
    acc_balance = acc.balance + tokens
    updated_acc = %{acc | balance: acc_balance}
    new_state = state ++ [updated_acc]
    {:reply, "Account balance updated!", new_state}
  end

  def handle_call({:update_account_balance_minus, acc, tokens}, _from, state) do
    state = state -- [acc]
    new_acc_balance = acc.balance - tokens
    updated_acc = %{acc | ballance: new_acc_balance}
    new_state = state ++ [updated_acc]
    {:reply, "Account balance updated!", new_state}
  end

end
