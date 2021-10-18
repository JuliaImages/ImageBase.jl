"""
    minimum_finite([f=identity], A; kwargs...)

Calculate `minimum(f, A)` while ignoring any values that are not finite, e.g., `Inf` or
`NaN`.

If `A` is a colorant array with multiple channels (e.g., `Array{RGB}`), the `min` comparison
is done in channel-wise sense.

The supported `kwargs` are those of `minimum(f, A; kwargs...)`.
"""
function minimum_finite(f, A::AbstractArray{T}; kwargs...) where T
    # FIXME(johnnychen94): if `typeof(f(first(A))) != eltype(A)`, this function is not type-stable.
    mapreduce(IfElse(isfinite, f, typemax), minc, A; kwargs...)
end
minimum_finite(A::AbstractArray; kwargs...) = minimum_finite(identity, A; kwargs...)

"""
    maximum_finite([f=identity], A; kwargs...)

Calculate `maximum(f, A)` while ignoring any values that are not finite, e.g., `Inf` or
`NaN`.

If `A` is a colorant array with multiple channels (e.g., `Array{RGB}`), the `max` comparison
is done in channel-wise sense.

The supported `kwargs` are those of `maximum(f, A; kwargs...)`.
"""
function maximum_finite(f, A::AbstractArray{T}; kwargs...) where T
    # FIXME(johnnychen94): if `typeof(f(first(A))) != eltype(A)`, this function is not type-stable
    mapreduce(IfElse(isfinite, f, typemin), maxc, A; kwargs...)
end
maximum_finite(A::AbstractArray; kwargs...) = maximum_finite(identity, A; kwargs...)

"""
    sumfinite([f=identity], A; kwargs...)

Compute `sum(f, A)` while ignoring any non-finite values.

The supported `kwargs` are those of `sum(f, A; kwargs...)`.
"""
sumfinite(A; kwargs...) = sumfinite(identity, A; kwargs...)

if Base.VERSION >= v"1.1"
    sumfinite(f, A; kwargs...) = sum(IfElse(isfinite, f, zero), A; kwargs...)
else
    sumfinite(f, A; kwargs...) = sum(IfElse(isfinite, f, zero).(A); kwargs...)
end

"""
    meanfinite([f=identity], A; kwargs...)

Compute `mean(f, A)` while ignoring any non-finite values.

The supported `kwargs` are those of `sum(f, A; kwargs...)`.
"""
meanfinite(A; kwargs...) = meanfinite(identity, A; kwargs...)

if Base.VERSION >= v"1.1"
    function meanfinite(f, A; kwargs...)
        s = sumfinite(f, A; kwargs...)
        n = sum(IfElse(isfinite, x->true, x->false), A; kwargs...)   # TODO: replace with `Returns`
        return s./n
    end
else
    function meanfinite(f, A; kwargs...)
        s = sumfinite(f, A; kwargs...)
        n = sum(IfElse(isfinite, x->true, x->false).(A); kwargs...)
        return s./n
    end
end

"""
    varfinite(A; kwargs...)

Compute the variance of `A`, ignoring any non-finite values.

The supported `kwargs` are those of `Statistics.var(A; kwargs...)`.

!!! note
    This function can produce a seemingly suprising result if the input array is an RGB
    image. To make it more clear, the implementation is made so that
    `varfinite(img) ≈ varfinite(RGB.(img))` holds for any gray-scale image. See also
    https://github.com/JuliaGraphics/ColorVectorSpace.jl#abs-and-abs2 for more information.

See also [`varmult_finite(op, A)`](@ref) for custom multiplication behavior when element of
A is a vector-like object, e.g., `RGB`.
"""
@inline varfinite(A; kwargs...) = varmult_finite(⋅, A; kwargs...)

"""
    varmult_finite(op, itr; corrected::Bool=true, mean=Statistics.mean(itr), dims=:)

Compute the variance of elements of `itr`, using `op` as the multiplication operator.
Unlike [`varmult`](@ref), non-finite values are ignored.
"""
@inline function varmult_finite(op, A; corrected::Bool=true, dims=:, mean=meanfinite(A; dims=dims))
    # modified from ColorVectorSpace
    if dims === (:)
        _varmult_finite(op, A, mean, corrected)
    else
        _varmult_finite(op, A, mean, corrected, dims)
    end
end
function _varmult_finite(op, A, mean, corrected::Bool)
    map_op = IfElse(isfinite,
        c->(Δc = c-mean; op(Δc, Δc)),
        i->zero(_number_type(typeof(i)))
    )
    # TODO(johnnychen94): calculate v and n in one for-loop for better performance
    init = zero(maybe_floattype(_number_type(eltype(A))))
    v = mapreduce(map_op, +, A; init=init)
    n = count_finite(A)
    if n == 0 || n == 1
        return zero(v) / zero(n) # a type-stable NaN
    else
        return v / (corrected ? max(1, n-1) : max(1, n))
    end
end
function _varmult_finite(op, A, mean, corrected::Bool, dims)
    # TODO: avoid temporary creation
    map_op = IfElse(isfinite,
        Δc->op(Δc, Δc),
        i->zero(_number_type(eltype(A)))
    )
    # TODO(johnnychen94): calculate v and n in one for-loop for better performance
    init = zero(maybe_floattype(_number_type(eltype(A))))
    v = mapreduce(map_op, +, A .- mean; dims=dims, init=init)
    n = count_finite(A; dims=dims)
    map(v, n) do vᵢ, nᵢ
        if nᵢ == 0 || nᵢ == 1
            return zero(vᵢ) / zero(nᵢ) # a type-stable NaN
        else
            return vᵢ / (corrected ? max(1, nᵢ-1) : max(1, nᵢ))
        end
    end
end
_number_type(::Type{T}) where T = T
_number_type(::Type{CT}) where CT<:Color = eltype(CT)

if VERSION >= v"1.1"
    count_finite(A; kwargs...) = sum(IfElse(isfinite, x->true, x->false), A; kwargs...)
else
    count_finite(A; kwargs...) = sum(IfElse(isfinite, identity, zero).(abs2.(A .- m)); kwargs...)
end
