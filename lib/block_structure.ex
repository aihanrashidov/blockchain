defmodule BlockStructure do

  defstruct head: %{ index: nil, hash: nil, previous_hash: nil, timestamp: nil, difficulty_target: nil, nonce: 0, merkle_root_hash: nil, chain_state_hash: nil}, transaction_list: []

end
