# BEGIN 0.1 deprecation

@deprecate restrict(A::AbstractArray, region::Vector{Int}) restrict(A, (region...,))

@deprecate meanfinite(A::AbstractArray, region) meanfinite(A; dims=region)

# END 0.1 deprecation
