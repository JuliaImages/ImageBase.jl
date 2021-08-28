module ImageBase

export
    # two-fold downsampling
    # originally from ImageTransformations.jl
    restrict,

    # finite difference on one-dimension
    # originally from Images.jl
    fdiff,
    fdiff!,

    # basic image statistics, from Images.jl
    minfinite,
    maxfinite,
    maxabsfinite,
    meanfinite


using Reexport

using Base.Cartesian: @nloops
@reexport using ImageCore
using ImageCore.OffsetArrays

include("diff.jl")
include("restrict.jl")
include("statistics.jl")
include("compat.jl")
include("deprecated.jl")

if VERSION >= v"1.4.2" # work around https://github.com/JuliaLang/julia/issues/34121
    include("precompile.jl")
    _precompile_()
end

end
