# ValueDispatch.jl

[![Build Status](https://github.com/ojwoodford/ValueDispatch.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ojwoodford/ValueDispatch.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![codecov](https://codecov.io/gh/ojwoodford/ValueDispatch.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ojwoodford/ValueDispatch.jl)

Compile-time binary-search value dispatch from runtime integers to `Static.StaticInt` in Julia.

## Why ValueDispatch.jl?

In high-performance Julia code, methods are often specialized on compile-time `Static.StaticInt` parameters—for example, to unroll loops, eliminate branches, or specialize on bitmask flags and dimension sizes. However, integer values frequently originate from runtime computations.

Converting a runtime integer `v` to a `StaticInt` via naive dynamic dispatch:

```julia
f(static(v))
```

is slow because:
1. **Type Instability**: `static(v)` cannot be statically inferred by the Julia compiler because its return type depends on the runtime value `v`.
2. **Dynamic Dispatch Overhead**: The subsequent call `f(...)` must perform runtime method table lookup and argument boxing on every invocation, adding ~70–160 ns of latency per call.
3. **Missed Compiler Optimizations**: Because the call target is unresolved at compile time, inlining and constant propagation across the call boundary are blocked.

`ValueDispatch.jl` solves this by replacing dynamic dispatch with a generated, fully unrolled compile-time binary-search decision tree over a bounded range `[lower, upper]`. At each leaf of the tree, the function is invoked with a statically known `StaticInt`, completely eliminating runtime method lookup overhead and enabling compiler optimizations.

## Performance Evaluation

A benchmark script is provided in [`examples/speed_test.jl`](examples/speed_test.jl). It measures the time per call of dynamic dispatch `f(static(v))` versus `valuedispatch(lower, upper, v, f)` across various range sizes.

To isolate and measure pure dispatch and function-call latency (avoiding artificial compiler optimizations like inlining or compile-time constant folding), the test function is annotated with `@noinline` and uses `Base.inferencebarrier`. The script warms up all code paths on unsorted data before evaluating both unsorted inputs (random branch patterns) and sorted inputs (predictable branch patterns).

To run the speed test:

```bash
julia --project=. examples/speed_test.jl
```

### Benchmark Results

Results collected on an Apple Silicon (M-series) CPU ($N = 1{,}000{,}000$ iterations per range):

#### Unsorted Inputs (Random / Branch Misses)

| Range | Values | Dynamic Dispatch | ValueDispatch | Speedup | Time Reduction |
|:-----:|:------:|:----------------:|:-------------:|:-------:|:--------------:|
| `0:1` | 2 | ~76.6 ns | ~5.5 ns | ~14.0x | ~92.8% |
| `0:3` | 4 | ~81.6 ns | ~8.5 ns | ~9.6x | ~89.6% |
| `0:7` | 8 | ~127.5 ns | ~13.2 ns | ~9.6x | ~89.6% |
| `0:15` | 16 | ~150.6 ns | ~17.5 ns | ~8.6x | ~88.4% |
| `0:31` | 32 | ~160.5 ns | ~20.1 ns | ~8.0x | ~87.5% |

#### Sorted Inputs (Predictable Branches)

| Range | Values | Dynamic Dispatch | ValueDispatch | Speedup | Time Reduction |
|:-----:|:------:|:----------------:|:-------------:|:-------:|:--------------:|
| `0:1` | 2 | ~70.3 ns | ~1.6 ns | ~44.5x | ~97.8% |
| `0:3` | 4 | ~70.6 ns | ~1.8 ns | ~39.5x | ~97.5% |
| `0:7` | 8 | ~70.9 ns | ~2.7 ns | ~26.4x | ~96.2% |
| `0:15` | 16 | ~70.7 ns | ~2.8 ns | ~25.2x | ~96.0% |
| `0:31` | 32 | ~73.4 ns | ~3.1 ns | ~23.7x | ~95.8% |

- **Zero Dynamic Invocation**: With a generated unrolled decision tree, Julia generates flat, direct branching code with zero runtime GC tracking, zero boxing, and zero runtime method lookup overhead.
- **Predictable Branches**: For sorted inputs, dispatch overhead across all evaluated ranges remains flat at **~1.6–3.1 ns** (>95% reduction in dispatch time).
- **Unsorted Robustness**: Even under random inputs with branch mispredictions, `ValueDispatch` achieves **8x–14x speedups** (~87%–93% time reduction) over dynamic dispatch.

## Externally Available Methods

### `valuedispatch`

```julia
valuedispatch(lower::StaticInt, upper::StaticInt, val::Int, fun)
valuedispatch(lower::StaticInt, upper::StaticInt, val::Integer, fun)
valuedispatch(lower::Integer, upper::Integer, val::Integer, fun)
```

Dispatches a runtime integer `val` within the interval `[lower, upper]` to the corresponding `StaticInt` using a generated compile-time unrolled binary search tree and calls `fun(static_val)`.

- **`lower`**: Lower bound of the dispatch range (`StaticInt` or `Integer`).
- **`upper`**: Upper bound of the dispatch range (`StaticInt` or `Integer`).
- **`val`**: Runtime integer value to dispatch on. Clamped to `[lower, upper]` if outside the bounds.
- **`fun`**: Callable invoked with the matched `StaticInt` value `fun(static(val))`.

#### Example

```julia
using ValueDispatch, Static

# Dispatch a runtime integer (0..7) to a StaticInt
res = valuedispatch(static(0), static(7), 3, identity)
# res === static(3)
```
