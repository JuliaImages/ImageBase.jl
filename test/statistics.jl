using ImageBase
using Statistics
using Test

using ColorVectorSpace: varmult

@testset "Reductions" begin
    _abs(x::Colorant) = mapreducec(abs, +, 0, x)

    @testset "sumfinite, meanfinite, varfinite" begin
        for T in generate_test_types([N0f8, Float32], [Gray, RGB])
            A = rand(T, 5, 5)
            s12 = sum(A, dims=(1,2))
            @test eltype(s12) <: Union{T, float(T), float64(T)}

            @test sumfinite(A) ≈ sum(A)
            @test sumfinite(A, dims=1) ≈ sum(A, dims=1)
            @test sumfinite(A, dims=(1, 2)) ≈ sum(A, dims=(1, 2))

            @test meanfinite(A) ≈ mean(A)
            @test meanfinite(A, dims=1) ≈ mean(A, dims=1)
            @test meanfinite(A, dims=(1, 2)) ≈ mean(A, dims=(1, 2))

            @test varfinite(A) ≈ varmult(⋅, A)
            @test varfinite(A, dims=1) ≈ varmult(⋅, A, dims=1)
            @test varfinite(A, dims=(1, 2)) ≈ varmult(⋅, A, dims=(1, 2))

            # test NaN/Inf
            if eltype(T) != N0f8
                A = rand(T, 5, 5) .- 0.5 .* oneunit(T)
                A[1] = Inf
                @test sum(A) ≈ A[1]
                @test sum(abs, A) ≈ A[1]
                @test sumfinite(A) ≈ sum(A[2:end])
                @test sumfinite(abs, A) ≈ sum(abs, A[2:end])
                A[1] = NaN
                @test isnan(sum(A))
                @test isnan(sum(abs, A))
                @test sumfinite(A) ≈ sum(A[2:end])
                @test sumfinite(abs, A) ≈ sum(abs, A[2:end])

                A = rand(T, 5, 5) .- 0.5 .* oneunit(T)
                A[1] = Inf
                @test mean(A) ≈ A[1]
                @test mean(abs, A) ≈ A[1]
                @test meanfinite(A) ≈ mean(A[2:end])
                @test meanfinite(abs, A) ≈ mean(abs, A[2:end])
                A[1] = NaN
                @test isnan(mean(A))
                @test isnan(mean(abs, A))
                @test meanfinite(A) ≈ mean(A[2:end])
                @test meanfinite(abs, A) ≈ mean(abs, A[2:end])

                A = rand(T, 5, 5)
                A[1] = Inf
                @test isnan(varmult(⋅, A))
                @test varfinite(A) ≈ varmult(⋅, A[2:end])
                A[1] = NaN
                @test isnan(varmult(⋅, A))
                @test varfinite(A) ≈ varmult(⋅, A[2:end])
            end
        end

        A = [NaN, 1, 2, 3]
        @test meanfinite(A, dims=1) ≈ [2]
        @test varfinite(A, dims=1) ≈ [1]

        A = [NaN NaN 1;
            1 2 3]
        vf = varfinite(A, dims=2)
        @test isnan(vf[1])

        A = [NaN 1 2 3;
            NaN 6 5 4]
        mf = meanfinite(A, dims=1)
        vf = varfinite(A, dims=1)
        @test isnan(mf[1])
        @test mf[2:end] ≈ [3.5,3.5,3.5]
        @test isnan(vf[1])
        @test vf[2:end] ≈ [12.5,4.5,0.5]

        @test meanfinite(A, dims=2) ≈ reshape([2, 5], 2, 1)
        @test varfinite(A, dims=2) ≈ reshape([1, 1], 2, 1)

        @test meanfinite(A, dims=(1,2)) ≈ [3.5]
        @test varfinite(A, dims=(1,2)) ≈ [3.5]
    end

    @test minfinite(A) == 1
    @test maxfinite(A) == 6
    @test maxabsfinite(A) == 6
    A = rand(10:20, 5, 5)
    @test minfinite(A) == minimum(A)
    @test maxfinite(A) == maximum(A)
    A = reinterpret(N0f8, rand(0x00:0xff, 5, 5))
    @test minfinite(A) == minimum(A)
    @test maxfinite(A) == maximum(A)
    A = rand(Float32,3,5,5)
    img = colorview(RGB, A)
    dc = meanfinite(img, dims=1)-reshape(reinterpretc(RGB{Float32}, mean(A, dims=2)), (1,5))
    @test maximum(map(_abs, dc)) < 1e-6
    dc = minfinite(img)-RGB{Float32}(minimum(A, dims=(2,3))...)
    @test _abs(dc) < 1e-6
    dc = maxfinite(img)-RGB{Float32}(maximum(A, dims=(2,3))...)
    @test _abs(dc) < 1e-6
end
