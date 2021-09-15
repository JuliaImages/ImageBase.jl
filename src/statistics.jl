"""
    Map12(condition, f1, f2)

Creates a function mapping `x -> condition(x) ? f1(x) : f2(x)`.
"""
struct Map12{C,F1,F2}
    condition::C
    f1::F1
    f2::F2
end
(m::Map12)(x) = m.condition(x) ? m.f1(x) : m.f2(x)

minc(x, y) = min(x, y)
minc(x::Color, y::Color) = mapc(min, x, y)
maxc(x, y) = max(x, y)
maxc(x::Color, y::Color) = mapc(max, x, y)

"""
    minfinite(A; kwargs...)

Calculate the minimum value in `A`, ignoring any values that are not finite (Inf or NaN).

The supported `kwargs` are those of `minimum(f, A; kwargs...)`.
"""
minfinite(A; kwargs...) = mapreduce(Map12(isfinite, identity, typemax), minc, A; kwargs...)

"""
    maxfinite(A; kwargs...)

Calculate the maximum value in `A`, ignoring any values that are not finite (Inf or NaN).

The supported `kwargs` are those of `maximum(f, A; kwargs...)`.
"""
maxfinite(A; kwargs...) = mapreduce(Map12(isfinite, identity, typemin), maxc, A; kwargs...)

"""
    maxabsfinite(A; kwargs...)

Calculate the maximum absolute value in `A`, ignoring any values that are not finite (Inf or NaN).

The supported `kwargs` are those of `maximum(f, A; kwargs...)`.
"""
maxabsfinite(A; kwargs...) = mapreduce(Map12(isfinite, abs, typemin), maxc, A; kwargs...)

"""
    meanfinite(A; kwargs...)

Compute the mean value of `A`, ignoring any non-finite values.

The supported `kwargs` are those of `sum(f, A; kwargs...)`.
"""
function meanfinite end

if Base.VERSION >= v"1.1"
    function meanfinite(A; kwargs...)
        s = sum(Map12(isfinite, identity, zero), A; kwargs...)
        n = sum(Map12(isfinite, x->true, x->false), A; kwargs...)   # TODO: replace with `Returns`
        return s./n
    end
else
    function meanfinite(A; kwargs...)
        s = sum(Map12(isfinite, identity, zero).(A); kwargs...)
        n = sum(Map12(isfinite, x->true, x->false).(A); kwargs...)
        return s./n
    end
end

"""
    varfinite(A; kwargs...)

Compute the variance of `A`, ignoring any non-finite values.

The supported `kwargs` are those of `sum(f, A; kwargs...)`.
"""
function varfinite end

if Base.VERSION >= v"1.1"
    function varfinite(A; kwargs...)
        m = meanfinite(A; kwargs...)
        n = sum(Map12(isfinite, x->true, x->false), A; kwargs...)   # TODO: replace with `Returns`
        s = sum(Map12(isfinite, identity, zero), (A .- m).^2; kwargs...)
        return s ./ max.(0, (n .- 1))
    end
else
    function varfinite(A; kwargs...)
        m = meanfinite(A; kwargs...)
        n = sum(Map12(isfinite, x->true, x->false).(A); kwargs...) 
        s = sum(Map12(isfinite, identity, zero).((A .- m).^2); kwargs...)
        return s ./ max.(0, (n .- 1))
    end
end
    