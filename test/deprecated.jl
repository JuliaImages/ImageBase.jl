@testset "deprecation" begin
    @testset "restrict" begin
        A = rand(N0f8, 4, 5, 3)
        @test restrict(A, [1, 2]) == restrict(A, (1, 2))
    end
end
