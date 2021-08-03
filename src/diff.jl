# TODO: add keyword `shrink` to give a consistant result on Base
#       when this is done, then we can propose this change to upstream Base
"""
    fdiff(v::AbstractVector; rev=false)
    fdiff(A::AbstractArray; dims::Int, rev=false)

A cyclic one-dimension finite difference operator on array `A`. Unlike `Base.diff`, this
function doesn't shrink the array size.

Take vector as an example, it computes `(A[2]-A[1], A[3]-A[2], ..., A[1]-A[end])`. If `rev==true`,
then it computes `(A[end]-A[1], A[1]-A[2], A[2]-A[3], ..., A[end-1]-A[end])`.

# Examples

```jldoctest; setup=:(using ImageBase: fdiff)
julia> A = [2 4 8; 3 9 27; 4 16 64]
3×3 $(Matrix{Int}):
 2   4   8
 3   9  27
 4  16  64

julia> diff(A, dims=2)
3×2 $(Matrix{Int}):
  2   4
  6  18
 12  48

julia> fdiff(A, dims=2)
3×3 $(Matrix{Int}):
  2   4   -6
  6  18  -24
 12  48  -60
```

See also [`fdiff!`](@ref) for the in-place version.
"""
fdiff(A::AbstractArray; kwargs...) = fdiff!(similar(A), A; kwargs...)

"""
    fdiff!(dst::AbstractArray, src::AbstractArray; dims::Int)

The in-place version of [`ImageBase.fdiff`](@ref)
"""
function fdiff!(dst::AbstractArray, src::AbstractArray; dims=_fdiff_default_dims(src), rev=false)
    isnothing(dims) && throw(UndefKeywordError(:dims))
    axes(dst) == axes(src) || throw(ArgumentError("axes of all input arrays should be equal. Instead they are $(axes(dst)) and $(axes(src))."))
    N = ndims(src)
    1 <= dims <= N || throw(ArgumentError("dimension $dims out of range (1:$N)"))

    r = axes(src)
    r0 = ntuple(i -> i == dims ? UnitRange(first(r[i]), last(r[i]) - 1) : UnitRange(r[i]), N)
    r1 = ntuple(i -> i == dims ? UnitRange(first(r[i])+1, last(r[i])) : UnitRange(r[i]), N)

    d0 = ntuple(i -> i == dims ? UnitRange(last(r[i]), last(r[i])) : UnitRange(r[i]), N)
    d1 = ntuple(i -> i == dims ? UnitRange(first(r[i]), first(r[i])) : UnitRange(r[i]), N)

    if rev
        dst[r1...] = view(src, r0...) .- view(src, r1...)
        dst[d1...] = view(src, d0...) .- view(src, d1...)
    else
        dst[r0...] = view(src, r1...) .- view(src, r0...)
        dst[d0...] = view(src, d1...) .- view(src, d0...)
    end

    return dst
end

_fdiff_default_dims(A) = nothing
_fdiff_default_dims(A::AbstractVector) = 1
