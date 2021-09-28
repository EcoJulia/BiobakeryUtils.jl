# Welcome to the BiobakeryUtils tutorial

## Using BiobakeryUtils with [MetaPhlAn](https://github.com/biobakery/MetaPhlAn/wiki/MetaPhlAn-3.0) files
Note: BiobakeryUtils currently only works with MetaPhlAn 3.0.

### Input file format

BiobakeryUtils accepts `.tsv` files outputted from MetaPhlAn.
Files can either contain a merged table or one or multiple single table(s).
Example files that are used in this tutorial can be found in [BiobakeryUtils.jl/test/files/](https://github.com/BioJulia/BiobakeryUtils.jl/tree/main/test/files).

### Creating CommunityProfiles

A [`CommunityProfile`](@ref) can be created from MetaPhlAn file(s) using [`metaphlan_profile`](@ref) and [`metaphlan_profiles`](@ref).

From one file with a single table:

``` julia
julia> metaphlan_profile("test/files/metaphlan_single2.tsv")
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 96 things in 1 places

Thing names:
Bacteria, Archaea, Firmicutes...Ruminococcus_bromii, Bacteroides_vulgatus

Place names:
metaphlan_single2
```

From one file with a merged table:

``` julia
julia> metaphlan_profiles("test/files/metaphlan_multi_test.tsv")
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 42 things in 7 places

Thing names:
Archaea, Euryarchaeota, Methanobacteria...Actinomyces_viscosus, GCF_000175315

Place names:
sample1_taxonomic, sample2_taxonomic, sample3_taxonomic...sample6_taxonomic, sample7_taxonomic
```

From multiple files with single tables:

```julia
julia> metaphlan_profiles(["test/files/metaphlan_single1.tsv", "test/files/metaphlan_single2.tsv"])
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 129 things in 2 places

Thing names:
Bacteria, Firmicutes, Bacteroidetes...Coprococcus_eutactus, Ruminococcus_bromii

Place names:
metaphlan_single1, metaphlan_single2
```

### Creating more specific CommunityProfiles

When creating a CommunityProfile, data to be compiled can be selected by specifying taxonomic level.

Taxonomic levels may be given either as numbers or symbols:
- `1` = `:kingdom`
- `2` = `:phylum`
- `3` = `:class`
- `4` = `:order`
- `5` = `:family`
- `6` = `:genus`
- `7` = `:species`
- `8` = `:subspecies`


```julia
julia> metaphlan_profile("test/files/metaphlan_single2.tsv", :genus)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 40 things in 1 places

Thing names:
Prevotella, Roseburia, Faecalibacterium...Haemophilus, Lactococcus

Place names:
metaphlan_single2
```

```julia
julia> metaphlan_profile("test/files/metaphlan_single2.tsv", 4)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 11 things in 1 places

Thing names:
Clostridiales, Bacteroidales, Coriobacteriales...Firmicutes_unclassified, Pasteurellales

Place names:
metaphlan_single2
```

When creating a CommunityProfile from a merged table, data from unidentified taxa can be kept in by setting the `keepunidentified` flag to `true`. The default is to filter out unidentified data.

```julia
# EXAMPLES WITH KEEPUNIDENTIFIED = TRUE AND FALSE
```

### Indexing CommunityProfiles
CommunityProfiles can be indexed using items in "Thing names" and "Place names".

```julia
julia> profile = metaphlan_profiles("test/files/metaphlan_multi_test.tsv")CommunityProfile{Float64, Taxon, MicrobiomeSample} with 42 things in 7 places
Thing names:
Archaea, Euryarchaeota, Methanobacteria...Actinomyces_viscosus, GCF_000175315

Place names:
sample1_taxonomic, sample2_taxonomic, sample3_taxonomic...sample6_taxonomic, sample7_taxonomic



julia> profile[:, "sample1_taxonomic"]
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 42 things in 1 places

Thing names:
Archaea, Euryarchaeota, Methanobacteria...Actinomyces_viscosus, GCF_000175315

Place names:
sample1_taxonomic



julia> profile["Archaea", :]
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 1 things in 7 places

Thing names:
Archaea

Place names:
sample1_taxonomic, sample2_taxonomic, sample3_taxonomic...sample6_taxonomic, sample7_taxonomic



julia> profile["Actinomycetales", "sample3_taxonomic"]
0.08487

julia> profile["Actinobacteria", ["sample1_taxonomic", "sample3_taxonomic"]]
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 1 things in 2 places

Thing names:
Actinobacteria

Place names:
sample1_taxonomic, sample3_taxonomic



julia> profile[["Actinobacteria", "Methanobacteria"], "sample1_taxonomic"]
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 2 things in 1 places

Thing names:
Actinobacteria, Methanobacteria

Place names:
sample1_taxonomic
```

### Parsing taxa

A string representing taxonmic levels as formatted by MetaPhlAn can be separated by taxonomic levels into elements of type Taxon in a vector.

```julia
julia> parsetaxa("k__Archaea|p__Euryarchaeota|c__Methanobacteria"; throw_error = true)
3-element Vector{Taxon}:
 Taxon("Archaea", :kingdom)
 Taxon("Euryarchaeota", :phylum)
 Taxon("Methanobacteria", :class)
```

Specific taxonomic levels (given as either numbers or symbols) can be pulled out.

```julia
julia> parsetaxon("k__Archaea|p__Euryarchaeota|c__Methanobacteria", 2)
Taxon("Euryarchaeota", :phylum)
```

```julia
julia> parsetaxon("k__Archaea|p__Euryarchaeota|c__Methanobacteria", :kingdom)
Taxon("Archaea", :kingdom)
```