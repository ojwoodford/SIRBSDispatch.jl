using SIRBSDispatch, Static, Test

@testset "SIRBSDispatch.jl" begin
    # Dispatch over a range of runtime integers
    for v in 0:7
        @test sirbsdispatch(static(0), static(7), v, identity) === static(v)
    end

    # Single-element range (lower == upper)
    @test sirbsdispatch(static(3), static(3), 3, x -> x + static(1)) === static(4)

    # Inverted range (lower > upper returns fun(upper))
    @test sirbsdispatch(static(5), static(2), 4, identity) === static(2)

    # Out-of-bounds clamping behavior
    @test sirbsdispatch(static(2), static(6), 0, identity) === static(2)
    @test sirbsdispatch(static(2), static(6), 10, identity) === static(6)

    # Negative ranges and non-Int integer types
    for v in -3:3
        @test sirbsdispatch(static(-3), static(3), Int32(v), x -> dynamic(x) * 2) == 2 * v
    end
    @test sirbsdispatch(1, 5, 4, identity) === static(4)
    @test sirbsdispatch(1, 5, Int32(2), identity) === static(2)
end
