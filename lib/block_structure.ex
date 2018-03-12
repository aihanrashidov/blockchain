defmodule BlockStructure do

  defstruct head: %{ hash: nil, previous_hash: nil, difficulty_target: nil, nonce: 0}, transaction_list: []
    
end
