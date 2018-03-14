defmodule Accounts do

  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_)do
    state = []
    {:ok, state}
  end

  def show_accounts() do
    GenServer.call(__MODULE__, {:show_accounts})
  end

  def create_account(name, tokens) do
    GenServer.call(__MODULE__, {:create_account, name, tokens})
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
      ballance: tokens
    }
    new_state = state ++ [acc_details]
    {:reply, "New account has been created!", new_state}
  end

end
