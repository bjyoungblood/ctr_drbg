defmodule CtrDrbg do
  @moduledoc """
  Pure Elixir implementation of the CTR_DRBG PRNG algorithm.

  ## Examples

      iex> state = CtrDrbg.init(:crypto.strong_rand_bytes(16))
      iex> {state, random_bytes} = CtrDrbg.generate(state, 32)
      {#CtrDrbg<...>, <<...>>}
  """

  @typedoc "The current PRNG state."
  @opaque t :: %__MODULE__{}

  @derive {Inspect, only: []}
  @enforce_keys [:k, :v]
  defstruct [:k, :v]

  @block_size 16
  @seed_size 32

  @doc """
  Initialize and seed the generator.
  """
  @spec init(binary(), binary()) :: t()
  def init(entropy, pstring \\ <<>>) do
    seed = exor(entropy, pstring)

    reseed(
      %__MODULE__{v: null_pad(16), k: null_pad(16)},
      seed
    )
  end

  @doc """
  Reseed the generator.
  """
  @spec reseed(t(), binary(), binary()) :: t()
  def reseed(state, seed, additional_entropy_input \\ <<>>) do
    seed = exor(seed, additional_entropy_input)
    update(state, seed)
  end

  @doc """
  Generate an arbitrary number of random bytes.
  """
  @spec generate(t(), pos_integer(), binary()) :: {t(), binary()}
  def generate(state, length \\ 16, additional_entropy_input \\ <<>>) do
    state =
      if byte_size(additional_entropy_input) > 0 do
        update(state, additional_entropy_input)
      else
        state
      end

    output_blocks = ceil(length / @block_size)

    {v, output} = next(output_blocks, state.k, state.v)

    state = %{state | v: v}

    {update(state, additional_entropy_input), binary_slice(output, 0..(length - 1))}
  end

  defp update(state, seed) do
    # for each 16-byte block of seed:
    #   increment V
    #   encrypt V using K
    #   pass V to the next iteration and append the output to the output block

    {_v, output} = next(ceil(@seed_size / @block_size), state.k, state.v)

    # XOR output with seed
    output = exor(output, seed)

    # K = first half of output
    # V = second half of output
    <<k::binary-size(16), v::binary-size(16)>> = output

    %{state | k: k, v: v}
  end

  defp increment(bin) do
    <<int_val::unit(8)-size(byte_size(bin))>> = bin
    <<int_val + 1::128>>
  end

  defp next(blocks, k, v, acc \\ <<>>)

  defp next(0, _k, v, acc) do
    {v, acc}
  end

  defp next(blocks, k, v, acc) do
    v = increment(v)
    block = :crypto.crypto_one_time(:aes_128_ecb, k, v, true)
    next(blocks - 1, k, v, acc <> block)
  end

  defp null_pad(binary \\ <<>>, length, direction \\ :leading)

  defp null_pad(binary, length, _direction) when byte_size(binary) >= length, do: binary

  defp null_pad(binary, length, direction) do
    filler = :binary.copy(<<0>>, length - byte_size(binary))

    case direction do
      :leading -> filler <> binary
      :trailing -> binary <> filler
    end
  end

  # Perform a bitwise exor on bin1 and bin2. If the two binaries are not the same
  # size, pad the smaller one with trailing null bytes (X ^ 0 == X). If either binary
  # is empty, return the other.
  defp exor(bin1, bin2) when byte_size(bin1) == 0, do: bin2
  defp exor(bin1, bin2) when byte_size(bin2) == 0, do: bin1

  defp exor(bin1, bin2) when byte_size(bin1) < byte_size(bin2) do
    bin1 = null_pad(bin1, byte_size(bin2), :trailing)
    exor(bin1, bin2)
  end

  defp exor(bin1, bin2) when byte_size(bin1) > byte_size(bin2) do
    bin2 = null_pad(bin2, byte_size(bin1), :trailing)
    exor(bin1, bin2)
  end

  defp exor(bin1, bin2) when byte_size(bin1) == byte_size(bin2) do
    :crypto.exor(bin1, bin2)
  end
end
