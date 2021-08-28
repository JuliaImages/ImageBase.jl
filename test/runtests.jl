using ImageBase, OffsetArrays, StackViews
using Test, TestImages, Aqua, Documenter

using OffsetArrays: IdentityUnitRange

@testset "ImageBase.jl" begin

    @testset "Project meta quality checks" begin
        # Not checking compat section for test-only dependencies
        Aqua.test_ambiguities(ImageBase)
        Aqua.test_all(ImageBase;
            ambiguities=false,
            project_extras=true,
            deps_compat=true,
            stale_deps=true,
            project_toml_formatting=true
        )
        if VERSION >= v"1.2"
            doctest(ImageBase,manual = false)
        end
    end

    include("diff.jl")
    include("restrict.jl")
    include("statistics.jl")

    @info "deprecations are expected"
    include("deprecated.jl")
end
