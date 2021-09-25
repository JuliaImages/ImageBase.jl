"""
    minfinite(A; kwargs...)

Calculate the minimum value in `A`, ignoring any values that are not finite (Inf or NaN).

The supported `kwargs` are those of `minimum(f, A; kwargs...)`.
"""
minfinite(A; kwargs...) = mapreduce(IfElse(isfinite, identity, typemax), minc, A; kwargs...)

"""
    maxfinite(A; kwargs...)

Calculate the maximum value in `A`, ignoring any values that are not finite (Inf or NaN).

The supported `kwargs` are those of `maximum(f, A; kwargs...)`.
"""
maxfinite(A; kwargs...) = mapreduce(IfElse(isfinite, identity, typemin), maxc, A; kwargs...)

"""
    maxabsfinite(A; kwargs...)

Calculate the maximum absolute value in `A`, ignoring any values that are not finite (Inf or NaN).

The supported `kwargs` are those of `maximum(f, A; kwargs...)`.
"""
maxabsfinite(A; kwargs...) = mapreduce(IfElse(isfinite, abs, typemin), maxc, A; kwargs...)

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

The supported `kwargs` are those of `sum(f, A; kwargs...)`.
"""
function varfinite end

if Base.VERSION >= v"1.1"
    function varfinite(A; kwargs...)
        m = meanfinite(A; kwargs...)
        n = sum(IfElse(isfinite, x->true, x->false), A; kwargs...)   # TODO: replace with `Returns`
        s = sum(IfElse(isfinite, identity, zero), abs2.(A .- m); kwargs...)
        return s ./ max.(0, (n .- 1))
    end
else
    function varfinite(A; kwargs...)
        m = meanfinite(A; kwargs...)
        n = sum(IfElse(isfinite, x->true, x->false).(A); kwargs...)
        s = sum(IfElse(isfinite, identity, zero).(abs2.(A .- m)); kwargs...)
        return s ./ max.(0, (n .- 1))
    end
end
