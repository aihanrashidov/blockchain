# Blockchain

**A simple blockchain implementation using Elixir.**

## How to use

1. Start the server with Blockchain.start_link().
2. Create accounts with Accounts.create_account(String, Integer).
   - The first parameter is a string used for the account name.
   - The second parameter is an integer for account balance tokens. By default is 0.
3. After you have created accounts now you can make transactions and mine blocks.
   - To make a transaction between accounts use Blockchain.make_transaction(String, String, Integer)
     - First and second parameter are strings used to specify the public keys of the sending and receiving account.
     - The third parameter is an integer specifying the sent amount.
   - To mine a new block use Blockchain.create_block(String)
     - String specifying the account from which the new block is mined.
4. To see the blocks in the chain use Blockchain.show_blocks()
5. To see the accounts use Accounts.show_accounts()
6. To see the transactions pool use Pool.show_transactions_pool()
7. To see the coinbase use Coinbase.get_total_value()

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `blockchain` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:blockchain, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/blockchain](https://hexdocs.pm/blockchain).
