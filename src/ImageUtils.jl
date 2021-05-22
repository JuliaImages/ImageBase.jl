module ImageUtils

export restrict

using Base.Cartesian: @nloops
using ImageCore
using ImageCore.OffsetArrays

include("restrict.jl")
include("compat.jl")

end
