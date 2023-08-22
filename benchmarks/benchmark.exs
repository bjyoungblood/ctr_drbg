{opts, _, _} = OptionParser.parse(System.argv(), strict: [save: :boolean, profile: :string])

:rand.seed({:exsss, [203_174_340_550_522_226 | 57_531_746_987_733_918]})

initial_state = CtrDrbg.init(:rand.bytes(16))

config = [
  load: Path.join(__DIR__, "*.benchee"),
  inputs: %{
    "16 bytes" => %{bytes: 16, state: initial_state},
    "32 bytes" => %{bytes: 32, state: initial_state},
    "64 bytes" => %{bytes: 64, state: initial_state}
  }
]

config =
  if opts[:save] do
    tag = [?v | Application.spec(:ctr_drbg, :vsn)] |> to_string()
    [save: [path: Path.join(__DIR__, "benchmark.benchee"), tag: tag]] ++ config
  else
    config
  end

config =
  case opts[:profile] do
    nil -> config
    "cprof" -> [profile: :cprof] ++ config
    "eprof" -> [profile: :eprof] ++ config
    "fprof" -> [profile: :fprof] ++ config
    _ -> [profile: true] ++ config
  end

config
|> Benchee.init()
|> Benchee.system()
|> Benchee.benchmark(
  "CtrDrbg.generate/2",
  fn %{state: state, bytes: bytes} -> CtrDrbg.generate(state, bytes) end
)
|> Benchee.collect()
|> Benchee.statistics()
|> Benchee.load()
|> Benchee.relative_statistics()
|> Benchee.Formatter.output()
|> Benchee.profile()
