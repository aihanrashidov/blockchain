defmodule Keys do

  def create_keys do
    entropy_byte_size = 16
    private_key = :crypto.strong_rand_bytes(entropy_byte_size)
    public_key = :crypto.generate_key(:ecdh, :secp256k1, private_key) |> elem(0)
    private_key = Base.encode16(private_key)
    public_key = Base.encode16(public_key)
    {private_key, public_key}
  end

end
