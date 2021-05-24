using ImageBase, ImageCore, OffsetArrays
using Test, TestImages

@testset "ImageBase.jl" begin
    include("restrict.jl")

    @info "deprecations are expected"
    include("deprecated.jl")
end
