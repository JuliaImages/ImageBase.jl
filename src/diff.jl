abstract type BoundaryCondition end
struct Periodic <: BoundaryCondition end
struct ZeroFill <: BoundaryCondition end

"""
    DiffView(A::AbstractArray, dims::Val{D}, [bc::BoundaryCondition=Periodic()], [rev=Val(false)])

Lazy version of finite difference [`fdiff`](@ref).

!!! tip
    For performance, both `dims` and `rev` require `Val` types.

# Arguments

- `dims::Val{D}`
  Specify the dimension D that dinite difference is applied to.
- `rev::Bool`
  If `rev==Val(true)`, then it computes the backward difference
  `(A[end]-A[1], A[1]-A[2], ..., A[end-1]-A[end])`.
- `boundary::BoundaryCondition`
  By default it computes periodically in the boundary, i.e., `Periodic()`.
  In some cases, one can fill zero values with `ZeroFill()`.
"""
struct DiffView{T,N,D,BC,REV,AT<:AbstractArray} <: AbstractArray{T,N}
    data::AT
end
function DiffView(
        data::AbstractArray{T,N},
        ::Val{D},
        bc::BoundaryCondition=Periodic(),
        rev::Val = Val(false)
    ) where {T,N,D}
    DiffView{maybe_floattype(T),N,D,typeof(bc),typeof(rev),typeof(data)}(data)
end

Base.size(A::DiffView) = size(A.data)
Base.axes(A::DiffView) = axes(A.data)
Base.IndexStyle(::DiffView) = IndexCartesian()

Base.@propagate_inbounds function Base.getindex(A::DiffView{T,N,D,Periodic,Val{true}}, I::Vararg{Int, N}) where {T,N,D}
    data = A.data
    r = axes(data, D)
    x = I[D]
    x_prev = first(r) == x ? last(r) : x - 1
    I_prev = update_tuple(I, x_prev, Val(D))
    return convert(T, data[I...]) - convert(T, data[I_prev...])
end
Base.@propagate_inbounds function Base.getindex(A::DiffView{T,N,D,Periodic,Val{false}}, I::Vararg{Int, N}) where {T,N,D}
    data = A.data
    r = axes(data, D)
    x = I[D]
    x_next = last(r) == x ? first(r) : x + 1
    I_next = update_tuple(I, x_next, Val(D))
    return convert(T, data[I_next...]) - convert(T, data[I...])
end
Base.@propagate_inbounds function Base.getindex(A::DiffView{T,N,D,ZeroFill,Val{false}}, I::Vararg{Int, N}) where {T,N,D}
    data = A.data
    x = I[D]
    if last(axes(data, D)) == x
        zero(T)
    else
        I_next = update_tuple(I, x+1, Val(D))
        convert(T, data[I_next...]) - convert(T, data[I...])
    end
end
Base.@propagate_inbounds function Base.getindex(A::DiffView{T,N,D,ZeroFill,Val{true}}, I::Vararg{Int, N}) where {T,N,D}
    data = A.data
    x = I[D]
    if first(axes(data, D)) == x
        zero(T)
    else
        I_prev = update_tuple(I, x-1, Val(D))
        convert(T, data[I...]) - convert(T, data[I_prev...])
    end
end

@generated function update_tuple(A::NTuple{N, T}, x::T, ::Val{i}) where {T, N, i}
    # This is equivalent to `ntuple(j->j==i ? x : A[j], N)` but is optimized by moving
    # the if branches to compilation time.
    ex = :()
    for j in Base.OneTo(N)
        new_x = i == j ? :(x) : :(A[$j])
        ex = :($ex..., $new_x)
    end
    return ex
end

# TODO: add keyword `shrink` to give a consistant result on Base
#       when this is done, then we can propose this change to upstream Base
"""
    fdiff(A::AbstractArray; dims::Int, rev=false, boundary=:periodic)

A one-dimension finite difference operator on array `A`. Unlike `Base.diff`, this function doesn't
shrink the array size.

Take vector as an example, it computes `(A[2]-A[1], A[3]-A[2], ..., A[1]-A[end])`.

# Keywords

- `rev::Bool`
  If `rev==true`, then it computes the backward difference
  `(A[end]-A[1], A[1]-A[2], ..., A[end-1]-A[end])`.
- `boundary`
  By default it computes periodically in the boundary, i.e., `:periodic`.
  In some cases, one can fill zero values with `boundary=:zero`.

# Examples

```jldoctest; setup=:(using ImageBase: fdiff)
julia> A = [2 4 8; 3 9 27; 4 16 64]
3×3 $(Matrix{Int}):
 2   4   8
 3   9  27
 4  16  64

julia> diff(A, dims=2) # this function exists in Base
3×2 $(Matrix{Int}):
  2   4
  6  18
 12  48

julia> fdiff(A, dims=2)
3×3 $(Matrix{Int}):
  2   4   -6
  6  18  -24
 12  48  -60

julia> fdiff(A, dims=2, rev=true) # reverse diff
3×3 $(Matrix{Int}):
  -6   2   4
 -24   6  18
 -60  12  48

julia> fdiff(A, dims=2, boundary=:zero) # fill boundary with zeros
3×3 $(Matrix{Int}):
  2   4  0
  6  18  0
 12  48  0
```

See also [`fdiff!`](@ref) for the in-place version, and [`DiffView`](@ref) for the
non-allocating version.
"""
fdiff(A::AbstractArray; kwargs...) = fdiff!(similar(A, maybe_floattype(eltype(A))), A; kwargs...)

"""
    fdiff!(dst::AbstractArray, src::AbstractArray; dims::Int, rev=false, boundary=:periodic)

The in-place version of [`fdiff`](@ref).
"""
function fdiff!(dst::AbstractArray, src::AbstractArray;
        dims=_fdiff_default_dims(src),
        rev=false,
        boundary::Symbol=:periodic)
    isnothing(dims) && throw(UndefKeywordError(:dims))
    axes(dst) == axes(src) || throw(ArgumentError("axes of all input arrays should be equal. Instead they are $(axes(dst)) and $(axes(src))."))
    N = ndims(src)
    1 <= dims <= N || throw(ArgumentError("dimension $dims out of range (1:$N)"))

    src = of_eltype(maybe_floattype(eltype(dst)), src)
    r = axes(src)
    r0 = ntuple(i -> i == dims ? UnitRange(first(r[i]), last(r[i]) - 1) : UnitRange(r[i]), N)
    r1 = ntuple(i -> i == dims ? UnitRange(first(r[i])+1, last(r[i])) : UnitRange(r[i]), N)

    d0 = ntuple(i -> i == dims ? UnitRange(last(r[i]), last(r[i])) : UnitRange(r[i]), N)
    d1 = ntuple(i -> i == dims ? UnitRange(first(r[i]), first(r[i])) : UnitRange(r[i]), N)

    if rev
        dst[r1...] .= view(src, r1...) .- view(src, r0...)
        if boundary == :periodic
            dst[d1...] .= view(src, d1...) .- view(src, d0...)
        elseif boundary == :zero
            dst[d1...] .= zero(eltype(dst))
        else
            throw(ArgumentError("Wrong boundary condition $boundary"))
        end
    else
        dst[r0...] .= view(src, r1...) .- view(src, r0...)
        if boundary == :periodic
            dst[d0...] .= view(src, d1...) .- view(src, d0...)
        elseif boundary == :zero
            dst[d0...] .= zero(eltype(dst))
        else
            throw(ArgumentError("Wrong boundary condition $boundary"))
        end
    end

    return dst
end

_fdiff_default_dims(A) = nothing
_fdiff_default_dims(A::AbstractVector) = 1

maybe_floattype(::Type{T}) where T = T
maybe_floattype(::Type{T}) where T<:FixedPoint = floattype(T)
maybe_floattype(::Type{CT}) where CT<:Color = base_color_type(CT){maybe_floattype(eltype(CT))}


"""
    fdiv(Vs::AbstractArray...)

Discrete divergence operator for vector field (V₁, V₂, ..., Vₙ).

See also [`fdiv!`](@ref) for the in-place version.
"""
fdiv(V₁::AbstractArray, Vs...) = fdiv!(similar(V₁, floattype(eltype(V₁))), V₁, Vs...)

"""
    fdiv!(dst::AbstractArray, Vs::AbstractArray...)

The in-place version of [`fdiv`](@ref).
"""
function fdiv!(dst::AbstractArray, Vs::AbstractArray...)
    # negative adjoint of gradient is equivalent to the reversed finite difference
    ∇ = fnegative_adjoint_gradient(Vs...)
    @inbounds for i in CartesianIndices(dst)
        dst[i] = heterogeneous_getindex_sum(i, ∇...)
    end
    return dst
end

@generated function heterogeneous_getindex_sum(i, Vs::Vararg{<:AbstractArray, N}) where N
    # This method is equivalent to `sum(V->V[i], Vs)` but is optimized for heterogeneous arrays
    ex = :(zero(eltype(Vs[1])))
    for j in Base.OneTo(N)
        ex = :($ex + Vs[$j][i])
    end
    return ex
end

"""
    flaplacian(X::AbstractArray)

The Laplacian operator ∇² is the divergence of the gradient operator.
"""
flaplacian(X::AbstractArray) = flaplacian!(similar(X, maybe_floattype(eltype(X))), X)

"""
    flaplacian!(dst::AbstractArray, X::AbstractArray)

The in-place version of the Laplacian operator [`laplacian`](@ref).
"""
flaplacian!(dst::AbstractArray, X::AbstractArray) = fdiv!(dst, fgradient(X)...)

# These two functions pass dimension information `Val(i)` to DiffView so that
# we can move computations to compilation time.
@generated function fgradient(X::AbstractArray{T, N}) where {T, N}
    ex = :()
    for i in Base.OneTo(N)
        new_x = :(DiffView(X, Val($i), Periodic(), Val(false)))
        ex = :($ex..., $new_x)
    end
    return ex
end
@generated function fnegative_adjoint_gradient(Vs::Vararg{<:AbstractArray, N}) where N
    ex = :()
    for i in Base.OneTo(N)
        new_x = :(DiffView(Vs[$i], Val($i), Periodic(), Val(true)))
        ex = :($ex..., $new_x)
    end
    return ex
end
