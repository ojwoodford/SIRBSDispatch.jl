using Aqua, SIRBSDispatch, Static, Test

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

    # Range size guard
    @test_throws ArgumentError sirbsdispatch(static(0), static(10^6), 5, identity)
    @test sirbsdispatch(static(0), static(4096), 4096, identity) === static(4096)

    # Integer bounds method infers when the bounds are literals
    literal_bounds(v) = sirbsdispatch(1, 5, v, x -> dynamic(x) * 2)
    @test @inferred(literal_bounds(3)) == 6

    # Specialization on a function passed through the forwarding methods
    fwd(v) = sirbsdispatch(static(1), static(3), v, x -> dynamic(x) + 1)
    @test @inferred(fwd(Int32(2))) == 3

    # Docstring documents the inverted-range behaviour
    doc = string(@doc sirbsdispatch)
    @test occursin("inverted", doc)
    @test occursin("4096", doc)
end

@testset "Aqua" begin
    Aqua.test_all(SIRBSDispatch)
end

@testset "Allocations" begin
    # Function-barrier call: the dispatch itself must not allocate
    @noinline barrier(x) = dynamic(x) * 2
    run(v) = sirbsdispatch(static(0), static(31), v, barrier)
    run(5) # compile
    @test (@allocated run(5)) == 0
    @test (@allocated run(31)) == 0
end
