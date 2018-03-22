defmodule Keys do

  @doc """
  This is the Keys module. Cointains a function for generating new private and
  public key pair.

  ##Parameters:
  No parameters.

  ##Examples:

    iex> {private_key, public_key} = Keys.create_keys
    {"6EBB7598B4E809E28D45E6DD42F1F16B",
    "0461743227DF8EDD2492E4240AD7658E14E444A0C45268E93001F577FC45A17F3B1136F4ED654C72A2F3AEB5797FD0603C9D14630B18FE40484C792EFAE2D1D9B9"}

  """

  @spec create_keys() :: {String, String}
  def create_keys() do
    entropy_byte_size = 16
    private_key = :crypto.strong_rand_bytes(entropy_byte_size)
    public_key = :crypto.generate_key(:ecdh, :secp256k1, private_key) |> elem(0)
    private_key = Base.encode16(private_key)
    public_key = Base.encode16(public_key)
    {private_key, public_key}
  end

end
