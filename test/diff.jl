@testset "forwarddiff and backwarddiff" begin
    @testset "API" begin
        # forwarddiff! works the same as forwarddiff
        mat_in = rand(3, 3, 3)
        mat_out = similar(mat_in)
        ImageBase.forwarddiff!(mat_out, mat_in, dims = 2)
        @test mat_out == ImageBase.forwarddiff(mat_in, dims = 2)

        # backdiff! works the same as backdiff
        mat_in = rand(3, 3, 3)
        mat_out = similar(mat_in)
        ImageBase.backdiff!(mat_out, mat_in, dims = 3)
        @test mat_out == ImageBase.backdiff(mat_in, dims = 3)
    end

    @testset "NumericalTests" begin
        a = reshape(collect(1:9), 3, 3)
        b_fd_1 = [1 1 1; 1 1 1; -2 -2 -2]
        b_fd_2 = [3 3 -6; 3 3 -6; 3 3 -6]
        b_bd_1 = [2 2 2; -1 -1 -1; -1 -1 -1]
        b_bd_2 = [6 -3 -3; 6 -3 -3; 6 -3 -3]
        out = similar(a)

        @test ImageBase.forwarddiff(a, dims = 1) == b_fd_1
        @test ImageBase.forwarddiff(a, dims = 2) == b_fd_2
        @test ImageBase.backdiff(a, dims = 1) == b_bd_1
        @test ImageBase.backdiff(a, dims = 2) == b_bd_2
        ImageBase.forwarddiff!(out, a, dims = 1)
        @test out == b_fd_1
        ImageBase.forwarddiff!(out, a, dims = 2)
        @test out == b_fd_2
        ImageBase.backdiff!(out, a, dims = 1)
        @test out == b_bd_1
        ImageBase.backdiff!(out, a, dims = 2)
        @test out == b_bd_2
    end
end
