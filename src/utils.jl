"""
    install_deps([env]; [force=false])

Uses Conda.jl to install HUMAnN and MetaPhlAn.
In order to use the commandline tools,
you must have the conda environment bin directory in `ENV["PATH"]`.
See "[Using Conda](@ref using-conda)" for more information.
"""
function install_deps(env=:BiobakeryUtils; force=false)
    if isdir(Conda.bin_dir(env)) && !force
        @warn """
        You already seem to have an environment, '$env'.
        If you've already installed the bioBakery packages, try

        `ENV["PATH"] = ENV["PATH"] * ":" * "$(Conda.bin_dir(env))"`

        Use `force=true` to install anyway"""
        return nothing
    end
    
    Conda.add_channel("bioconda", env)
    Conda.add_channel("conda-forge", env)
    Conda.add("humann", env)
    Conda.add("tbb=2020.2", env) # https://www.biostars.org/p/494922/

    @warn """
    Don't forget to add $(Conda.bin_dir(env)) to your PATH!
    
    This can be done in a julia session with:

    `ENV["PATH"] = ENV["PATH"] * ":" * "$(Conda.bin_dir(env))"`,
    or you can set it in your shell environment.
    """
    return nothing
end

function add_cli_kwargs!(cmd, kwargs)
    for (key,val) in pairs(kwargs)
        if val isa Bool
            val && push!(cmd, replace(string("--", key), "_"=>"-"))
        elseif val isa AbstractVector
            append!(cmd, [replace(string("--", key), "_"=>"-"), string.(val)...])
        else
            append!(cmd, [replace(string("--", key), "_"=>"-"), string(val)])
        end
    end
    return cmd
end