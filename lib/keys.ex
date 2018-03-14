defmodule Keys do

  def create_keys do
    entropy_byte_size = 16
    private_key = :crypto.strong_rand_bytes(entropy_byte_size) |> Base.encode16
    public_key = :crypto.generate_key(:ecdh, :secp256k1, private_key) |> elem(0) |> Base.encode16
    {private_key, public_key}
  end

end
