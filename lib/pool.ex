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

  @doc """
  Updates the state by adding the new transactions.

  ##Parameters:
  - transaction: Map of the newly made transaction.

  ##Examples:
  No Examples.

  """

  def add_to_pool(transaction) do
    GenServer.call(__MODULE__, {:add_to_pool, transaction})
  end

  @doc """
  Returns the state and then removes all transactions.

  ##Parameters:
  No parameters.

  ##Examples:
  No examples

  """

  def take_from_pool() do
    GenServer.call(__MODULE__, {:take_from_pool})
  end

  @doc """
  Returns the state (shows the transactions added to the pool).

  ##Parameters:
  No parameters.

  ##Examples:

    iex> Pool.show_transactions_pool()
    [
    %{
      amount: 1,
      from: "047367E041C1E68AD258BB764D70B0AC56394B00DCC9CCCE1AD9145468125CC2DF47AA20BC5B7B47F1BC679FF2798876DB50B01E861B041E8B04F28384BFE558E2",
      sig: "3045022100EA96EB1312F35F4BB01C1001A2D1E74A2524BF0B0CBCC9A84D72A27054561F820220334E35CE6C9C31A6B77CE3885B748C5D0C8B9D2A4A88605B92B3074341458861",
      to: "0409AF683D8B31357973CF00A70A1A1B9152F08D8A3D6C63847390B10808FA995B051B6AC89F0B0F76632EC51DDBEDEE86EB079683DBD57877C9F2E2A8CD887915"
      },
      %{
      amount: 2,
      from: "047367E041C1E68AD258BB764D70B0AC56394B00DCC9CCCE1AD9145468125CC2DF47AA20BC5B7B47F1BC679FF2798876DB50B01E861B041E8B04F28384BFE558E2",
      sig: "3046022100C6BA6FD1EB9374CBB600062D83972881A0E92D9A81EC7E3DA8A2111454A93B15022100BA516BC4640FDAF4E0E40A4B36657A1D677A0C4942DEF07787B2910E778862B8",
      to: "0409AF683D8B31357973CF00A70A1A1B9152F08D8A3D6C63847390B10808FA995B051B6AC89F0B0F76632EC51DDBEDEE86EB079683DBD57877C9F2E2A8CD887915"
      },
      %{
      amount: 5,
      from: "047367E041C1E68AD258BB764D70B0AC56394B00DCC9CCCE1AD9145468125CC2DF47AA20BC5B7B47F1BC679FF2798876DB50B01E861B041E8B04F28384BFE558E2",
      sig: "304502202D410F90043B4DE4D0803D4EBC1ABEDCFADCF6A611ED560EDA7B59055E24892F022100B7DD0151E314F76C44A8361D6BCE2463925136E173E3C6D492FCA7DFB852701E",
      to: "0409AF683D8B31357973CF00A70A1A1B9152F08D8A3D6C63847390B10808FA995B051B6AC89F0B0F76632EC51DDBEDEE86EB079683DBD57877C9F2E2A8CD887915"
    }
    ]

  """

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
