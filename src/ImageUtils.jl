module ImageUtils

export restrict

using Base.Cartesian: @nloops
using ImageCore

include("restrict.jl")

end
