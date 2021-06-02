using ImageBase, ImageCore, OffsetArrays
using Test, TestImages

using OffsetArrays: IdentityUnitRange

@testset "ImageBase.jl" begin
    include("restrict.jl")

    @info "deprecations are expected"
    include("deprecated.jl")
end
