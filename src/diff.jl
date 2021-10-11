abstract type BoundaryCondition end
struct Periodic <: BoundaryCondition end
struct ZeroFill <: BoundaryCondition end

"""
    DiffView(A::AbstractArray, [rev=Val(false)], [bc::BoundaryCondition=Periodic()]; dims)

Lazy version of finite difference [`fdiff`](@ref).

!!! tip
    For performance, `rev` should be stable type `Val(false)` or `Val(true)`.

# Arguments

- `rev::Bool`
  If `rev==Val(true)`, then it computes the backward difference
  `(A[end]-A[1], A[1]-A[2], ..., A[end-1]-A[end])`.
- `boundary::BoundaryCondition`
  By default it computes periodically in the boundary, i.e., `Periodic()`.
  In some cases, one can fill zero values with `ZeroFill()`.
"""
struct DiffView{T,N,AT<:AbstractArray,BC,REV} <: AbstractArray{T,N}
    data::AT
    dims::Int
end
function DiffView(
        data::AbstractArray{T,N},
        bc::BoundaryCondition=Periodic(),
        rev::Union{Val, Bool}=Val(false);
        dims=_fdiff_default_dims(data)) where {T,N}
    isnothing(dims) && throw(UndefKeywordError(:dims))
    rev = to_static_bool(rev)
    DiffView{maybe_floattype(T),N,typeof(data),typeof(bc),typeof(rev)}(data, dims)
end
function DiffView(
        data::AbstractArray,
        rev::Union{Val, Bool},
        bc::BoundaryCondition = Periodic();
        kwargs...)
    DiffView(data, bc, rev; kwargs...)
end

to_static_bool(x::Union{Val{true},Val{false}}) = x
function to_static_bool(x::Bool)
    @warn "Please use `Val($x)` for performance"
    return Val(x)
end

Base.size(A::DiffView) = size(A.data)
Base.axes(A::DiffView) = axes(A.data)
Base.IndexStyle(::DiffView) = IndexCartesian()

Base.@propagate_inbounds function Base.getindex(A::DiffView{T,N,AT,Periodic,Val{true}}, I::Vararg{Int, N}) where {T,N,AT}
    data = A.data
    I_prev = map(ntuple(identity, N), I, axes(data)) do i, p, r
        i == A.dims || return p
        p == first(r) && return last(r)
        p - 1
    end
    return convert(T, data[I...]) - convert(T, data[I_prev...])
end
Base.@propagate_inbounds function Base.getindex(A::DiffView{T,N,AT,Periodic,Val{false}}, I::Vararg{Int, N}) where {T,N,AT}
    data = A.data
    I_next = map(ntuple(identity, N), I, axes(data)) do i, p, r
        i == A.dims || return p
        p == last(r) && return first(r)
        p + 1
    end
    return convert(T, data[I_next...]) - convert(T, data[I...])
end
Base.@propagate_inbounds function Base.getindex(A::DiffView{T,N,AT,ZeroFill,Val{false}}, I::Vararg{Int, N}) where {T,N,AT}
    data = A.data
    I_next = I .+ ntuple(i->i==A.dims, N)
    if checkbounds(Bool, data, I_next...)
        vi = convert(T, data[I...]) # it requires the caller to pass @inbounds
        @inbounds convert(T, data[I_next...]) - vi
    else
        zero(T)
    end
end
Base.@propagate_inbounds function Base.getindex(A::DiffView{T,N,AT,ZeroFill,Val{true}}, I::Vararg{Int, N}) where {T,N,AT}
    data = A.data
    I_prev = I .- ntuple(i->i==A.dims, N)
    if checkbounds(Bool, data, I_prev...)
        vi = convert(T, data[I...]) # it requires the caller to pass @inbounds
        @inbounds vi - convert(T, data[I_prev...])
    else
        zero(T)
    end
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
    fdiv(Vs::AbstractArray...; boundary=:periodic)

Discrete divergence operator for vector field (V₁, V₂, ..., Vₙ).

# Example

Laplacian operator of array `A` is the divergence of its gradient vector field (∂₁A, ∂₂A, ..., ∂ₙA):

```jldoctest
julia> using ImageFiltering, ImageBase

julia> X = Float32.(rand(1:9, 7, 7));

julia> laplacian(X) = fdiv(ntuple(i->DiffView(X, dims=i), ndims(X))...)
laplacian (generic function with 1 method)

julia> laplacian(X) == imfilter(X, Kernel.Laplacian(), "circular")
true
```

See also [`fdiv!`](@ref) for the in-place version.
"""
function fdiv(V₁::AbstractArray, Vs...; kwargs...)
    fdiv!(similar(V₁, floattype(eltype(V₁))), V₁, Vs...; kwargs...)
end

"""
    fdiv!(dst::AbstractArray, Vs::AbstractArray...)

The in-place version of [`fdiv`](@ref).
"""
function fdiv!(dst::AbstractArray, Vs::AbstractArray...)
    ∇ = map(ntuple(identity, length(Vs)), Vs) do n, V
        DiffView(V, Val(true), dims=n)
    end
    @inbounds for i in CartesianIndices(dst)
        dst[i] = sum(x->_inbound_getindex(x, i), ∇)
    end
    return dst
end

@inline _inbound_getindex(x, i) = @inbounds x[i]
