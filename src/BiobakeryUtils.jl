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

function __init__()
    Conda.add_channel("bioconda", :BiobakeryUtils)
    Conda.add_channel("conda-forge", :BiobakeryUtils)
    Conda.add("humann", :BiobakeryUtils)
    Conda.add("tbb=2020.2", :BiobakeryUtils) # https://www.biostars.org/p/494922/
end

ENV["PATH"] = ENV["PATH"] * ':' * Conda.bin_dir(:BiobakeryUtils)

end