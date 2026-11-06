# Speed test comparing dynamic dispatch on StaticInt to compile-time SIRBSDispatch
using SIRBSDispatch
using Static
using Random

# Target function specialized on StaticInt.
# @noinline and Base.inferencebarrier ensure that dispatch and function calls are
# genuinely timed, preventing compiler inlining and compile-time constant folding.
@noinline function compute(::StaticInt{N})::Int where N
    return Base.inferencebarrier(N * N + 1)::Int
end

# Helper to time a loop over values
function timetrial(fn, vals)
    s = 0
    t0 = time_ns()
    @inbounds for v in vals
        s += fn(v)
    end
    t = (time_ns() - t0) / length(vals)
    return t, s
end

"""
    run_speed_test(N=1_000_000, trials=3)

Benchmark dynamic dispatch against `SIRBSDispatch.sirbsdispatch` across various ranges,
testing both unsorted (random branch patterns) and sorted (predictable branch patterns) inputs.
"""
function run_speed_test(N::Int=1_000_000, trials::Int=3)
    ranges = [
        (static(0), static(1)),   # 2 values (e.g. 1 bit)
        (static(0), static(3)),   # 4 values (e.g. 2 bits)
        (static(0), static(7)),   # 8 values (e.g. 3 bits)
        (static(0), static(15)),  # 16 values (e.g. 4 bits)
        (static(0), static(31)),  # 32 values (e.g. 5 bits)
    ]

    println("=" ^ 82)
    println("SIRBSDispatch.jl Speed Test: Dynamic Dispatch vs SIRBSDispatch")
    println("Iterations per range: $N | Trials: $trials")
    println("=" ^ 82)

    for is_sorted in (false, true)
        mode = is_sorted ? "Sorted Inputs (Predictable Branches)" : "Unsorted Inputs (Random / Branch Misses)"
        println("\n### $mode\n")
        println("| Range | Values | Dynamic Dispatch | SIRBSDispatch | Speedup | Time Reduction |")
        println("|:-----:|:------:|:----------------:|:-------------:|:-------:|:--------------:|")

        for (lower, upper) in ranges
            L, U = dynamic(lower), dynamic(upper)
            num_vals = U - L + 1
            vals = rand(L:U, N)

            dyn_call(v) = compute(static(v))
            vd_call(v) = sirbsdispatch(lower, upper, v, compute)

            # Warm-up JIT compilation on unsorted values so all code paths are compiled
            timetrial(dyn_call, vals[1:10_000])
            timetrial(vd_call, vals[1:10_000])

            # Sort vals after warming up to benchmark predictable branch patterns
            if is_sorted
                sort!(vals)
            end

            best_dyn = Inf
            best_vd = Inf
            s_dyn = 0
            s_vd = 0

            for _ in 1:trials
                t_d, s_dyn = timetrial(dyn_call, vals)
                t_v, s_vd = timetrial(vd_call, vals)
                best_dyn = min(best_dyn, t_d)
                best_vd = min(best_vd, t_v)
            end

            @assert s_dyn == s_vd "Results must match between implementations"
            speedup = best_dyn / best_vd
            reduction = (1.0 - best_vd / best_dyn) * 100.0

            t_dyn_str = string(round(best_dyn, digits=2), " ns")
            t_vd_str = string(round(best_vd, digits=2), " ns")
            speedup_str = string(round(speedup, digits=1), "x")
            red_str = string(round(reduction, digits=1), "%")

            println("| $L:$U | $num_vals | $t_dyn_str | $t_vd_str | $speedup_str | $red_str |")
        end
    end
    println()
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_speed_test()
end
