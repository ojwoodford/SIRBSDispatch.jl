module ValueDispatch

using Static

export valuedispatch

"""
    valuedispatch(lower::StaticInt, upper::StaticInt, val::Int, fun)
    valuedispatch(lower::Integer, upper::Integer, val::Integer, fun)

Converts a runtime integer `val` within the known static range `[lower, upper]` into a
compile-time `StaticInt` using a binary-search decision tree, and invokes `fun(static_val)`.

If `val <= lower`, `fun(static(lower))` is called; if `val >= upper`, `fun(static(upper))` is called.

# Example
```julia
using ValueDispatch, Static

y = valuedispatch(static(1), static(8), 5, x -> x + static(10)) # static(15)
```
"""
@inline function valuedispatch(lower::StaticInt, upper::StaticInt, val::Int, fun)
    if lower >= upper
        return fun(upper)
    end
    midpoint = lower + div(upper - lower, static(2))
    if val <= midpoint
        return valuedispatch(lower, midpoint, val, fun)
    else
        return valuedispatch(midpoint + static(1), upper, val, fun)
    end
end

@inline valuedispatch(lower::StaticInt, upper::StaticInt, val::Integer, fun) =
    valuedispatch(lower, upper, Int(val), fun)

@inline valuedispatch(lower::Integer, upper::Integer, val::Integer, fun) =
    valuedispatch(static(Int(lower)), static(Int(upper)), Int(val), fun)

end # module ValueDispatch
