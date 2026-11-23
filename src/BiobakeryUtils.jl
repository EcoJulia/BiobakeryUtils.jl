module BiobakeryUtils

export
    metaphlan_profile,
    metaphlan_profiles,
    taxfilter,
    taxfilter!,
    parsetaxa,
    parsetaxon,
    rm_strat!,
    permanova,
    humann_profile,
    humann_profiles,
    read_pcl,
    write_pcl

export read_metaphlan, read_humann

using Reexport
@reexport using Microbiome
using CSV
using Tables
using SparseArrays
using ReTest
using CodecXz
using CodecZlib

include("reading.jl")
include("metaphlan.jl")
include("humann.jl")

end
