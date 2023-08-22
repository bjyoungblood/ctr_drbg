# CtrDrbg [![Hex Version](https://img.shields.io/hexpm/v/ctr_drbg.svg)](https://hex.pm/packages/ctr_drbg) [![Hex Docs](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/ctr_drbg/)

A pure Elixir implementation of the CTR_DRBG PRNG algorithm.

## Supported Functionality

- Ciphers
  - [x] AES-128
  - [ ] AES-192
  - [ ] AES-256
  - [ ] Triple DES
- [x] Personalization string
- [ ] Reseeding counter
- [ ] Prediction resistance
- [ ] Derivation function
- [ ] Security strength option

## Installation

Add `ctr_drbg` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ctr_drbg, "~> 0.1.0"}
  ]
end
```

Docs can be found at <https://hexdocs.pm/ctr_drbg>.

## Tests

The test vectors under `text/fixtures` were retrieved from the [NIST's Cryptographic
Algorithm Validation Program](https://csrc.nist.gov/projects/cryptographic-algorithm-validation-program/random-number-generators#DRBG) (`drbgvectors_pr_false/CTR_DRBG.rsp` in the `drbgtestvectors.zip` archive).

## Benchmarks

```text
$> mix benchmark

Generated ctr_drbg app
Operating System: macOS
CPU Information: Apple M1 Max
Number of Available Cores: 10
Available memory: 32 GB
Elixir 1.15.4
Erlang 26.0.2

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
reduction time: 0 ns
parallel: 1
inputs: 16 bytes, 32 bytes, 64 bytes
Estimated total run time: 21 s

Benchmarking CtrDrbg.generate/2 with input 16 bytes ...
Benchmarking CtrDrbg.generate/2 with input 32 bytes ...
Benchmarking CtrDrbg.generate/2 with input 64 bytes ...

##### With input 16 bytes #####
Name                         ips        average  deviation         median         99th %
CtrDrbg.generate/2      427.59 K        2.34 μs  ±2044.84%        1.54 μs        3.58 μs

##### With input 32 bytes #####
Name                         ips        average  deviation         median         99th %
CtrDrbg.generate/2      401.58 K        2.49 μs   ±978.15%        1.92 μs        4.79 μs

##### With input 64 bytes #####
Name                         ips        average  deviation         median         99th %
CtrDrbg.generate/2      278.11 K        3.60 μs   ±558.63%        2.83 μs        7.25 μs
```
