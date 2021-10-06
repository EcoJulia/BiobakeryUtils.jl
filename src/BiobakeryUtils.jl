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
    humann_barplot,
    humann_barplots,
    qvalue!

using Reexport
@reexport using Microbiome
using Statistics
using CSV
using CSV.Tables
using RCall
using SparseArrays

include("general.jl")
include("metaphlan.jl")
include("humann.jl")

end
