@testset "deprecation" begin
    @testset "restrict" begin
        A = rand(N0f8, 4, 5, 3)
        @test restrict(A, [1, 2]) == restrict(A, (1, 2))
    end

    @testset "statistics" begin
        A = rand(Float32, 4, 4) .- 0.5
        @test minfinite(A, dims=1) == minimum_finite(A, dims=1)
        @test minfinite(A) == minimum_finite(A)
        @test maxfinite(A, dims=1) == maximum_finite(A, dims=1)
        @test maxfinite(A) == maximum_finite(A)

        @test maxabsfinite(A) == maximum_finite(abs, A)
        @test maxabsfinite(A, dims=1) == maximum_finite(abs, A, dims=1)
    end
end
