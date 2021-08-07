module ImageBase

export
    # two-fold downsampling
    # originally from ImageTransformations.jl
    restrict,

    # finite difference on one-dimension
    # originally from Images.jl
    fdiff,
    fdiff!


using Reexport

using Base.Cartesian: @nloops
@reexport using ImageCore
using ImageCore.OffsetArrays

include("diff.jl")
include("restrict.jl")
include("compat.jl")
include("deprecated.jl")

if VERSION >= v"1.4.2" # work around https://github.com/JuliaLang/julia/issues/34121
    include("precompile.jl")
    _precompile_()
end

end
