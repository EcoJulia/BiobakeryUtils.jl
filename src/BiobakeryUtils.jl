module BiobakeryUtils

export
    metaphlan,
    metaphlan_profile,
    metaphlan_profiles,
    humann_profile,
    humann_profiles,
    taxfilter,
    taxfilter!,
    parsetaxa,
    parsetaxon,
    rm_strat!,
    permanova,
    humann,
    humann_regroup,
    humann_rename,
    humann_renorm,
    humann_join,
    read_pcl,
    write_pcl,
    humann_barplot,
    humann_barplots

using Reexport
@reexport using Microbiome
using CSV
using CSV.Tables
using SparseArrays
using Conda

include("metaphlan.jl")
include("humann.jl")

"""
    install_deps([env])

Uses Conda.jl to install HUMAnN and MetaPhlAn.
In order to use the commandline tools,
you must have the conda environment bin directory in `ENV["PATH"]`.
See "[Using Conda](@ref using-conda)" for more information.
"""
function install_deps(env=:BiobakeryUtils)
    Conda.add_channel("bioconda", env)
    Conda.add_channel("conda-forge", env)
    Conda.add("humann", env)
    Conda.add("tbb=2020.2", env) # https://www.biostars.org/p/494922/

    @warn """
    Don't forget to add $(Conda.bin_dir(env)) to your PATH!
    
    This can be done in a julia session with:

    `ENV["PATH"] = ENV["PATH"] * ":" * $(Conda.bin_dir(env))`,
    or you can set it in your shell environment.
    """
end



end