using ImageBase, OffsetArrays, StackViews
using Test, TestImages, Aqua, Documenter

using OffsetArrays: IdentityUnitRange

@testset "ImageBase.jl" begin

    @testset "Project meta quality checks" begin
        # Not checking compat section for test-only dependencies
        ambiguity_exclude_list = [
            # https://github.com/JuliaDiff/ChainRulesCore.jl/pull/367#issuecomment-869071000
            Base.:(==),
        ]
        Aqua.test_ambiguities([ImageCore, Base, Core], exclude=ambiguity_exclude_list)
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

    @info "deprecations are expected"
    include("deprecated.jl")
end
