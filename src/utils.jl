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

function add_cli_kwargs!(cmd, kwargs; optunderscores=false)
    for (key,val) in pairs(kwargs)
        if val isa Bool
            val && push!(cmd, string("--", key))
        elseif val isa AbstractVector
            append!(cmd, [string("--", key), string.(val)...])
        else
            append!(cmd, [string("--", key), string(val)])
        end
    end
    !optunderscores && map(c-> startswith(c, "--") ? replace(c, "_"=>"-") : c, cmd)
    return cmd
end

function check_for_install(tool)
    try run(pipeline(`which $tool`, stdout=devnull))
        return nothing
    catch e
        @error """
        Can not find `$tool`! If you think it should be installed,
        try running:

        ```
        ENV["PATH"] = ENV["PATH"] * ":" * Conda.bin_dir(env))`
        ```
        """
        rethrow()
    end
    return nothing
end
