# ValueDispatch.jl

Compile-time binary-search value dispatch from runtime integers to `Static.StaticInt` in Julia.

## Overview

`ValueDispatch.jl` provides `valuedispatch`, which bridges a runtime integer `val` in a bounded range `[lower, upper]` to a compile-time `StaticInt` by unrolling a binary-search branch tree, enabling type-stable specialization without dynamic dispatch overhead.

## Externally Available Methods

### `valuedispatch`

```julia
valuedispatch(lower::StaticInt, upper::StaticInt, val::Int, fun)
valuedispatch(lower::StaticInt, upper::StaticInt, val::Integer, fun)
valuedispatch(lower::Integer, upper::Integer, val::Integer, fun)
```

Dispatches a runtime integer `val` within the interval `[lower, upper]` to the corresponding `StaticInt` using binary search and calls `fun(static_val)`.

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
