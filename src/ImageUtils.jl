module ImageUtils

export restrict

using Base.Cartesian: @nloops
using ImageCore
using ImageCore.OffsetArrays

include("restrict.jl")
include("compat.jl")

if VERSION >= v"1.4.2" # work around https://github.com/JuliaLang/julia/issues/34121
    include("precompile.jl")
    _precompile_()
end

end
