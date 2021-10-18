module ImageBase

export
    # two-fold downsampling
    # originally from ImageTransformations.jl
    restrict,

    # basic image statistics, from Images.jl
    minimum_finite,
    maximum_finite,
    meanfinite,
    varfinite,
    sumfinite

# Introduced in ColorVectorSpace v0.9.3
# https://github.com/JuliaGraphics/ColorVectorSpace.jl/pull/172
using ImageCore.ColorVectorSpace.Future: abs2

using Reexport

using Base.Cartesian: @nloops
@reexport using ImageCore
using ImageCore.OffsetArrays

include("diff.jl")
include("restrict.jl")
include("utils.jl")
include("statistics.jl")
include("deprecated.jl")

if VERSION >= v"1.4.2" # work around https://github.com/JuliaLang/julia/issues/34121
    include("precompile.jl")
    _precompile_()
end

end
