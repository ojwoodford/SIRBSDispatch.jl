module SIRBSDispatch

using Static

export sirbsdispatch

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
    sirbsdispatch(lower::StaticInt, upper::StaticInt, val::Int, fun)
    sirbsdispatch(lower::Integer, upper::Integer, val::Integer, fun)

Converts a runtime integer `val` within the known static range `[lower, upper]` into a
compile-time `StaticInt` using an unrolled binary-search decision tree, and invokes `fun(static_val)`.

If `val <= lower`, `fun(static(lower))` is called; if `val >= upper`, `fun(static(upper))` is called.

# Example
```julia
using SIRBSDispatch, Static

y = sirbsdispatch(static(1), static(8), 5, x -> x + static(10)) # static(15)
```
"""
@inline @generated function sirbsdispatch(::StaticInt{L}, ::StaticInt{U}, val::Int, fun) where {L, U}
    return build_dispatch_tree(L, U)
end

@inline sirbsdispatch(lower::StaticInt, upper::StaticInt, val::Integer, fun) =
    sirbsdispatch(lower, upper, Int(val), fun)

@inline sirbsdispatch(lower::Integer, upper::Integer, val::Integer, fun) =
    sirbsdispatch(static(Int(lower)), static(Int(upper)), Int(val), fun)

end # module SIRBSDispatch
