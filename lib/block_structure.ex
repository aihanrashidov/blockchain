defmodule BlockStructure do

  defstruct head: %{ index: nil, hash: nil, previous_hash: nil, timestamp: nil, difficulty_target: nil, nonce: 0}, transaction_list: []

end
