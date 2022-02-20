module BiobakeryUtils

export
    metaphlan,
    metaphlan_merge,
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
    humann_barplots,
    kneaddata,
    kneaddata_database,
    kneaddata_read_count_table

using Reexport
@reexport using Microbiome
using CSV
using Tables
using SparseArrays
using Conda
using ReTest

include("utils.jl")
include("metaphlan.jl")
include("humann.jl")
include("kneaddata.jl")


end