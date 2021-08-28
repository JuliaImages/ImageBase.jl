using ImageBase
using Statistics
using Test

@testset "Reductions" begin
    _abs(x::Colorant) = mapreducec(abs, +, 0, x)

    A = rand(5,5,3)
    img = colorview(RGB, PermutedDimsArray(A, (3,1,2)))
    s12 = sum(img, dims=(1,2))
    @test eltype(s12) <: RGB
    A = [NaN, 1, 2, 3]
    @test meanfinite(A, 1) ≈ [2]
    A = [NaN 1 2 3;
         NaN 6 5 4]
    mf = meanfinite(A, 1)
    @test isnan(mf[1])
    @test mf[1,2:end] ≈ [3.5,3.5,3.5]
    @test meanfinite(A, 2) ≈ reshape([2, 5], 2, 1)
    @test meanfinite(A, (1,2)) ≈ [3.5]
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
    dc = meanfinite(img, 1)-reshape(reinterpretc(RGB{Float32}, mean(A, dims=2)), (1,5))
    @test maximum(map(_abs, dc)) < 1e-6
    dc = minfinite(img)-RGB{Float32}(minimum(A, dims=(2,3))...)
    @test _abs(dc) < 1e-6
    dc = maxfinite(img)-RGB{Float32}(maximum(A, dims=(2,3))...)
    @test _abs(dc) < 1e-6
end
