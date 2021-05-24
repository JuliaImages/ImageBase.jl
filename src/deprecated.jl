# BEGIN 0.1 deprecation

@deprecate restrict(A::AbstractArray, region::Vector{Int}) restrict(A, (region...,))

# END 0.1 deprecation
