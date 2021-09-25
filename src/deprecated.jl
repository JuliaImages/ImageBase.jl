# BEGIN 0.1 deprecation

@deprecate restrict(A::AbstractArray, region::Vector{Int}) restrict(A, (region...,))

@deprecate meanfinite(A::AbstractArray, region) meanfinite(A; dims=region)

@deprecate minfinite(A; kwargs...) minimum_finite(A; kwargs...)
@deprecate maxfinite(A; kwargs...) maximum_finite(A; kwargs...)
@deprecate maxabsfinite(A; kwargs...) maximum_finite(abs, A; kwargs...)

# END 0.1 deprecation
