defmodule CtrDrbgTest do
  use ExUnit.Case, async: true

  @nist_vectors_file Path.join(__DIR__, "fixtures/ctr_drbg_pr_false.rsp")
  @external_resource @nist_vectors_file

  test "init, reseed, generate" do
    entropy = Base.decode16!("ED1E7F21EF66EA5D8E2A85B9337245445B71D6393A4EECB0E63C193D0F72F9A9")
    pstring = <<>>

    reseed_entropy_input =
      Base.decode16!("303FB519F0A4E17D6DF0B6426AA0ECB2A36079BD48BE47AD2A8DBFE48DA3EFAD")

    expected_output =
      Base.decode16!(
        "F80111D08E874672F32F42997133A5210F7A9375E22CEA70587F9CFAFEBE0F6A6AA2EB68E7DD9164536D53FA020FCAB20F54CADDFAB7D6D91E5FFEC1DFD8DEAA"
      )

    state = CtrDrbg.init(entropy, pstring)
    state = CtrDrbg.reseed(state, reseed_entropy_input)
    {state, _out} = CtrDrbg.generate(state, 64)
    {state, out} = CtrDrbg.generate(state, 64)

    assert out == expected_output

    assert state.k ==
             <<0x96, 0x4C, 0x57, 0x94, 0x6A, 0x10, 0x4A, 0xA9, 0x3F, 0xC3, 0xC2, 0x13, 0x7B, 0xB9,
               0xBC, 0x11>>

    assert state.v ==
             <<0x9D, 0x58, 0x00, 0x80, 0x33, 0xAC, 0x00, 0x7C, 0x9E, 0xAD, 0x25, 0x4B, 0xFA, 0x8D,
               0xE2, 0xB6>>
  end

  test "intermediate states" do
    entropy = Base.decode16!("F817EDC33537AF62B7E8C08745A59AB045A4991F6489ED48168BAD055A70424B")

    pstring = <<>>

    reseed_entropy_input =
      Base.decode16!("D52BAA3624C263304C096A48356F065519C7A7470891F6CE3A20A4F47EFD21C4")

    reseed_additional_input =
      Base.decode16!("63265BECDEAADB76A674221DB1D841BAD56BBC5D2AC1A54EC44DEAC5F7F28368")

    additional_input_1 =
      Base.decode16!("F78D6CB6EA0945E8FF9BC6F0C203D06BF2787835EF4A94F10B904592EED31AD7")

    additional_input_2 =
      Base.decode16!("8811EE4CAD917475DE9A7CA107498067D3944B14E203C3CF4C338766F06D00F7")

    state = CtrDrbg.init(entropy, pstring)

    assert state.k ==
             <<0xA0, 0xF5, 0x11, 0x0D, 0xCF, 0x49, 0x9F, 0x03, 0x81, 0x97, 0xDD, 0xD0, 0xE1, 0x42,
               0xDF, 0xEA>>

    assert state.v ==
             <<0x46, 0x2C, 0x43, 0xD1, 0x04, 0x3F, 0x4E, 0xDA, 0xE5, 0xA3, 0x6F, 0xBC, 0x2B, 0xC2,
               0xBC, 0x33>>

    state = CtrDrbg.reseed(state, reseed_entropy_input, reseed_additional_input)

    assert state.k ==
             <<0x42, 0xD0, 0x6C, 0xFE, 0x42, 0xB3, 0x08, 0xE5, 0xAE, 0x73, 0x06, 0xB6, 0x99, 0x4A,
               0x57, 0x52>>

    assert state.v ==
             <<0x11, 0x2B, 0x7B, 0x11, 0x84, 0x51, 0x0D, 0x98, 0x64, 0x84, 0x44, 0x13, 0xDF, 0xBC,
               0xEE, 0x15>>

    {state, out} = CtrDrbg.generate(state, 64, additional_input_1)

    assert state.k ==
             <<0x85, 0xEB, 0x89, 0xD1, 0xA9, 0x62, 0x50, 0xF0, 0xEE, 0x51, 0x7A, 0x37, 0xC8, 0xD8,
               0x3D, 0xEE>>

    assert state.v ==
             <<0xE4, 0x47, 0x60, 0x8D, 0xC9, 0x71, 0xB5, 0x75, 0x07, 0xEB, 0x92, 0xAA, 0xB3, 0xD8,
               0xE3, 0x63>>

    assert out ==
             <<0x7D, 0x03, 0x12, 0x55, 0x00, 0x3E, 0x0E, 0x71, 0x33, 0x01, 0x8D, 0xB4, 0x70, 0xF7,
               0x49, 0x69, 0x92, 0x68, 0xE8, 0xCF, 0x82, 0x55, 0x26, 0x8F, 0x7C, 0x2F, 0xC6, 0xCE,
               0x72, 0xB5, 0xB4, 0x17, 0x6B, 0x60, 0x83, 0xBA, 0xFD, 0x9F, 0xB0, 0xBE, 0x35, 0x86,
               0xC9, 0xB4, 0xE2, 0xDE, 0x8C, 0x4F, 0x5F, 0xF2, 0x24, 0xFF, 0xE2, 0x02, 0xAC, 0xA9,
               0xAE, 0x29, 0x25, 0x68, 0x3E, 0xA4, 0x59, 0x20>>

    {state, out} = CtrDrbg.generate(state, 64, additional_input_2)

    assert state.k ==
             <<0x71, 0x2E, 0xBD, 0x24, 0x39, 0xAB, 0xC8, 0xA2, 0x15, 0x38, 0x63, 0x69, 0x8C, 0x85,
               0x95, 0x1C>>

    assert state.v ==
             <<0x1D, 0xDE, 0xC9, 0x86, 0xE6, 0x49, 0x16, 0xFA, 0x97, 0x93, 0xD2, 0x24, 0x99, 0xFF,
               0xE9, 0xE5>>

    assert out ==
             <<0xBB, 0x71, 0xBC, 0x49, 0x79, 0x4D, 0xFE, 0x83, 0xCF, 0x07, 0xF4, 0x2E, 0xEB, 0x6E,
               0x41, 0xA4, 0x96, 0x10, 0xF1, 0xA1, 0xE5, 0x74, 0x59, 0x76, 0x4A, 0x40, 0x61, 0x1B,
               0x1B, 0x14, 0x47, 0xC2, 0x84, 0x39, 0x40, 0xA4, 0x76, 0x0C, 0xF3, 0x3B, 0x41, 0xF5,
               0xF1, 0x02, 0x51, 0xA8, 0xE8, 0x3A, 0xEA, 0xFA, 0xBA, 0xED, 0x1C, 0x28, 0x09, 0x1A,
               0xB5, 0x52, 0xBC, 0x76, 0x22, 0xF6, 0xEA, 0xC3>>
  end

  test "NIST test vectors" do
    vectors = load_vectors()

    for %{params: params, cases: cases} <- vectors,
        %{
          entropy_input: entropy_input,
          nonce: _nonce,
          personalization_string: personalization_string,
          reseed_entropy_input: reseed_entropy_input,
          reseed_additional_input: reseed_additional_input,
          additional_input_1: additional_input_1,
          additional_input_2: additional_input_2,
          returned_bits: returned_bits
        } = test_case <- cases do
      state = CtrDrbg.init(entropy_input, personalization_string)
      state = CtrDrbg.reseed(state, reseed_entropy_input, reseed_additional_input)
      {state, _out} = CtrDrbg.generate(state, byte_size(returned_bits), additional_input_1)
      {_state, out} = CtrDrbg.generate(state, byte_size(returned_bits), additional_input_2)

      assert out == returned_bits,
             """
             Case parameters: #{inspect(params)}

             Inputs:
             #{format_test_case(test_case)}

             Expected Output: #{Base.encode16(returned_bits, case: :lower)}
             Actual Output:   #{Base.encode16(out, case: :lower)}
             """
    end
  end

  defp format_test_case(%{
         entropy_input: entropy_input,
         nonce: nonce,
         personalization_string: personalization_string,
         reseed_entropy_input: reseed_entropy_input,
         reseed_additional_input: reseed_additional_input,
         additional_input_1: additional_input_1,
         additional_input_2: additional_input_2
       }) do
    """
      EntropyInput = #{Base.encode16(entropy_input, case: :lower)}
      Nonce = #{Base.encode16(nonce, case: :lower)}
      PersonalizationString = #{Base.encode16(personalization_string, case: :lower)}
      EntropyInputReseed = #{Base.encode16(reseed_entropy_input, case: :lower)}
      AdditionalInputReseed = #{Base.encode16(reseed_additional_input, case: :lower)}
      AdditionalInput1 = #{Base.encode16(additional_input_1, case: :lower)}
      AdditionalInput2 = #{Base.encode16(additional_input_2, case: :lower)}
    """
  end

  defp load_vectors() do
    stream = File.stream!(@nist_vectors_file, [:read])

    chunk_fun = fn element, acc ->
      if element =~ ~r/^\[[a-z0-9-]+ (use|no) df\]$/i do
        {:cont, acc, [element]}
      else
        {:cont, acc ++ [element]}
      end
    end

    after_fun = fn
      [] -> {:cont, []}
      acc -> {:cont, acc, []}
    end

    stream
    # Remove newlines
    |> Stream.map(&String.trim_trailing(&1, "\n"))
    # Reject comments
    |> Stream.reject(&String.starts_with?(&1, "#"))
    # Chunk into test cases grouped by algorithm parameters
    |> Stream.chunk_while([], chunk_fun, after_fun)
    # Reject empty chunks
    |> Stream.reject(&(&1 == []))
    # We're only testing AES-128 with no derivation function
    |> Stream.filter(&(List.first(&1) == "[AES-128 no df]"))
    # Parse the test cases
    |> Stream.map(fn block ->
      {params, rest} = block |> Enum.reject(&(&1 == "")) |> Enum.split(7)

      params =
        params
        # Drop the algorithm declaration
        |> Enum.drop(1)
        |> Enum.map(fn param_line ->
          [_match, key, value] = Regex.run(~r/\[([A-Za-z0-9]+) = ([A-Za-z0-9]+)\]/i, param_line)

          value =
            cond do
              value == "True" -> true
              value == "False" -> false
              value =~ ~r/^\d+$/ -> String.to_integer(value)
              true -> raise "unhandled algorithm parameter value for #{key}: #{inspect(value)}"
            end

          {key, value}
        end)
        |> Enum.into(%{})

      cases =
        rest
        |> Enum.chunk_every(9)
        |> Enum.map(fn [
                         _count,
                         "EntropyInput =" <> entropy_input,
                         "Nonce =" <> nonce,
                         "PersonalizationString =" <> personalization_string,
                         "EntropyInputReseed =" <> reseed_entropy_input,
                         "AdditionalInputReseed =" <> reseed_additional_input,
                         "AdditionalInput =" <> additional_input_1,
                         "AdditionalInput =" <> additional_input_2,
                         "ReturnedBits =" <> returned_bits
                       ] ->
          %{
            entropy_input: hex_to_raw(entropy_input),
            nonce: hex_to_raw(nonce),
            personalization_string: hex_to_raw(personalization_string),
            reseed_entropy_input: hex_to_raw(reseed_entropy_input),
            reseed_additional_input: hex_to_raw(reseed_additional_input),
            additional_input_1: hex_to_raw(additional_input_1),
            additional_input_2: hex_to_raw(additional_input_2),
            returned_bits: hex_to_raw(returned_bits)
          }
        end)

      %{params: params, cases: cases}
    end)
    |> Enum.into([])
  end

  defp hex_to_raw(""), do: ""
  defp hex_to_raw(binary), do: binary |> String.trim() |> Base.decode16!(case: :lower)
end
