"""
    IfElse(condition, f1, f2)

Create a function mapping `x -> condition(x) ? f1(x) : f2(x)`.

This is essentially the same as the anonymous function, but more
interpretable in stacktraces and more amenable to precompilation.
"""
struct IfElse{C,F1,F2}
    condition::C
    f1::F1
    f2::F2
end
(m::IfElse)(x) = m.condition(x) ? m.f1(x) : m.f2(x)

minc(x, y) = min(x, y)
minc(x::Color, y::Color) = mapc(min, x, y)
maxc(x, y) = max(x, y)
maxc(x::Color, y::Color) = mapc(max, x, y)
