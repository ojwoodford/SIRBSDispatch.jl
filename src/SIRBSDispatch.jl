module SIRBSDispatch

using Static

export sirbsdispatch

# Maximum number of values (U - L) in a range, to avoid compiling enormous trees.
const MAX_RANGE = 4096

function build_dispatch_tree(L::Int, U::Int)
    U - L <= MAX_RANGE || throw(ArgumentError(
        "sirbsdispatch range [$L, $U] is too large (U - L must be <= $MAX_RANGE)"))
    if L == U
        return :(fun(Static.static($U)))
    end
    midpoint = L + div(U - L, 2)
    return :(if val <= $midpoint
        $(build_dispatch_tree(L, midpoint))
    else
        $(build_dispatch_tree(midpoint + 1, U))
    end)
end

"""
    sirbsdispatch(lower::StaticInt, upper::StaticInt, val::Int, fun)
    sirbsdispatch(lower::Integer, upper::Integer, val::Integer, fun)

Converts a runtime integer `val` within the known static range `[lower, upper]` into a
compile-time `StaticInt` using an unrolled binary-search decision tree, and invokes `fun(static_val)`.

If `val <= lower`, `fun(static(lower))` is called; if `val >= upper`, `fun(static(upper))` is called.
An inverted range (`lower > upper`) is an error and throws an `ArgumentError`.
The range may span at most $MAX_RANGE values beyond `lower` (`upper - lower <= $MAX_RANGE`);
larger ranges throw an `ArgumentError`.

The `Integer` bounds method is only efficient when `lower` and `upper` are compile-time
constants (e.g. literals), so that `static(Int(lower))` constant-folds. With runtime-valued
bounds the `StaticInt` type is not inferable and the call dispatches dynamically, losing the
benefit of this package; pass `StaticInt` bounds instead.

# Example
```julia
using SIRBSDispatch, Static

y = sirbsdispatch(static(1), static(8), 5, x -> x + static(10)) # static(15)
```
"""
@inline @generated function sirbsdispatch(::StaticInt{L}, ::StaticInt{U}, val::Int, fun::F) where {L, U, F}
    L <= U || throw(ArgumentError(
        "sirbsdispatch requires lower <= upper, got lower = $L, upper = $U"))
    return build_dispatch_tree(L, U)
end

@inline sirbsdispatch(lower::StaticInt, upper::StaticInt, val::Integer, fun::F) where {F} =
    sirbsdispatch(lower, upper, Int(val), fun)

@inline sirbsdispatch(lower::Integer, upper::Integer, val::Integer, fun::F) where {F} =
    sirbsdispatch(static(Int(lower)), static(Int(upper)), Int(val), fun)

end # module SIRBSDispatch
