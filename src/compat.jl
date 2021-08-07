if VERSION < v"1.2"
    require_one_based_indexing(A...) = !Base.has_offset_axes(A...) || throw(ArgumentError("offset arrays are not supported but got an array with index other than 1"))
else
    const require_one_based_indexing = Base.require_one_based_indexing
end

if VERSION < v"1.1"
    isnothing(x) = x === nothing
end
