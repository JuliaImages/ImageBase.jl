using ImageUtils, ImageCore, OffsetArrays
using Test, TestImages

@testset "ImageUtils.jl" begin
    include("restrict.jl")

    @info "deprecations are expected"
    include("deprecated.jl")
end
