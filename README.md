# ImageBase

[![Build Status](https://github.com/JuliaImages/ImageBase.jl/workflows/CI/badge.svg)](https://github.com/JuliaImages/ImageBase.jl/actions)
[![Coverage](https://codecov.io/gh/JuliaImages/ImageBase.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaImages/ImageBase.jl)

This is a twin package to [ImageCore] with functions that are used among many of the packages in JuliaImages.
The main purpose of this package is to reduce unnecessary compilation overhead from external dependencies.

This package reexports [ImageCore] so can be a direct replacement of it.

This package can be seen as an experimental package inside JuliaImages:

1. functions here might be moved to a seperate package if they get better supports (with more dependency), and
2. is very conservative to external dependencies outside JuliaImages unless there is a real need, in which case,
   it may just fit the first case.

Functions provided by this package:

- `restrict` for two-fold image downsample. (Originally from ImageTransformations.jl)
- finite difference operator `fdiff`/`fdiff!` (Originally from Images.jl)


[ImageCore]: https://github.com/JuliaImages/ImageCore.jl
