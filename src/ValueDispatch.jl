module ValueDispatch

using Static

export valuedispatch

function build_dispatch_tree(L::Int, U::Int)
    if L >= U
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
    valuedispatch(lower::StaticInt, upper::StaticInt, val::Int, fun)
    valuedispatch(lower::Integer, upper::Integer, val::Integer, fun)

Converts a runtime integer `val` within the known static range `[lower, upper]` into a
compile-time `StaticInt` using an unrolled binary-search decision tree, and invokes `fun(static_val)`.

If `val <= lower`, `fun(static(lower))` is called; if `val >= upper`, `fun(static(upper))` is called.

# Example
```julia
using ValueDispatch, Static

y = valuedispatch(static(1), static(8), 5, x -> x + static(10)) # static(15)
```
"""
@inline @generated function valuedispatch(::StaticInt{L}, ::StaticInt{U}, val::Int, fun) where {L, U}
    return build_dispatch_tree(L, U)
end

@inline valuedispatch(lower::StaticInt, upper::StaticInt, val::Integer, fun) =
    valuedispatch(lower, upper, Int(val), fun)

@inline valuedispatch(lower::Integer, upper::Integer, val::Integer, fun) =
    valuedispatch(static(Int(lower)), static(Int(upper)), Int(val), fun)

end # module ValueDispatch
