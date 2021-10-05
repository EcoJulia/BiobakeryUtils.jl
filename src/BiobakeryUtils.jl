module BiobakeryUtils

export
    import_abundance_tables,
    import_abundance_table,
    clean_abundance_tables,
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
    humann2_regroup,
    humann2_rename,
    humann2_barplot,
    humann2_barplots,
    qvalue!

using Statistics
using CSV
using CSV.Tables
using RCall
using Microbiome
using SparseArrays

include("general.jl")
include("metaphlan.jl")
include("humann.jl")

function __init__()
    
end

end
