#==============
MetaPhlAn Utils
==============#
const taxonlevels = (
    kingdom      = 1,
    phylum       = 2,
    class        = 3,
    order        = 4,
    family       = 5,
    genus        = 6,
    species      = 7,
    subspecies   = 8,
    unidentified = 0)

const shortlevels = (
    k = :kingdom,
    p = :phylum,
    c = :class,
    o = :order,
    f = :family,
    g = :genus,
    s = :species,
    t = :subspecies,
    u = missing)

function _split_clades(clade_string)
    clades = split(clade_string, '|')
    taxa = Taxon[]
    for clade in clades
        spl = split(clade, "__")
        (level, name) = length(spl) == 1 ? ("u", spl[1]) : spl
        push!(taxa, Taxon(name, shortlevels[Symbol(level)]))
    end
    return taxa
end

"""
    metaphlan_profile(path::AbstractString, level::Union{Int, Symbol}=:all; sample::AbstractString=basename(first(splitext(path))))

Compiles a MetaPhlAn file into a CommunityProfile.
Can select data according to taxonomic level. If level not given, all data is compiled.
`Place name` of the CommunityProfile can be specified by passing a `sample` argument. If name not given, the name of the file becomes the `Place name`.

Levels may be given either as numbers or symbols:

- `1` = `:kingdom`
- `2` = `:phylum`
- `3` = `:class`
- `4` = `:order`
- `5` = `:family`
- `6` = `:genus`
- `7` = `:species`
- `8` = `:subspecies`

```jldoctest metaphlan_profile

Examples
≡≡≡≡≡≡≡≡≡≡
julia> metaphlan_profile("test/files/metaphlan_single2.tsv")
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 96 things in 1 places

Thing names:
Bacteria, Archaea, Firmicutes...Ruminococcus_bromii, Bacteroides_vulgatus

Place names:
metaphlan_single2



julia> metaphlan_profile("test/files/metaphlan_single2.tsv", 4)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 11 things in 1 places

Thing names:
Clostridiales, Bacteroidales, Coriobacteriales...Firmicutes_unclassified, Pasteurellales

Place names:
metaphlan_single2



julia> metaphlan_profile("test/files/metaphlan_single2.tsv", :genus)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 40 things in 1 places

Thing names:
Prevotella, Roseburia, Faecalibacterium...Haemophilus, Lactococcus

Place names:
metaphlan_single2



julia> metaphlan_profile("test/files/metaphlan_single2.tsv", :genus, sample = "sample2")
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 40 things in 1 places

Thing names:
Prevotella, Roseburia, Faecalibacterium...Haemophilus, Lactococcus

Place names:
sample2
```
"""
function metaphlan_profile(path::AbstractString, level=:all; sample=basename(first(splitext(path))))
    profile = CSV.read(path, datarow=5, header=["clade", "NCBI_taxid", "abundance", "additional_species"], Tables.columntable)
    taxa = [last(_split_clades(c)) for c in profile.clade]
    mat = sparse(reshape(profile.abundance, length(profile.abundance), 1))
    sample = sample isa Microbiome.AbstractSample ? sample : MicrobiomeSample(sample)
    keep = level == :all ? Colon() : [ismissing(c) || c == level for c in clade.(taxa)]
    return CommunityProfile(mat[keep, :], taxa[keep], [sample])
end

function metaphlan_profile(path::AbstractString, level::Int; sample=basename(first(splitext(path))))
    level = keys(taxonlevels)[level]
    metaphlan_profile(path, level; sample)
end

"""
    metaphlan_profiles(path::AbstractString, level::Union{Int, Symbol}=:all; keepunidentified=false)

Compiles MetaPhlAn profiles from a merged table into a CommunityProfile.
Can select data according to taxonomic level. If level not given, all data is compiled.
Set `keepunidentified` flag to `true` to keep `UNIDENTIFIED` data.

Levels may be given either as numbers or symbols:

- `1` = `:kingdom`
- `2` = `:phylum`
- `3` = `:class`
- `4` = `:order`
- `5` = `:family`
- `6` = `:genus`
- `7` = `:species`
- `8` = `:subspecies`

```jldoctest metaphlan_profiles

Examples
≡≡≡≡≡≡≡≡≡≡
julia> metaphlan_profiles("test/files/metaphlan_multi_test.tsv")
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 42 things in 7 places

Thing names:
Archaea, Euryarchaeota, Methanobacteria...Actinomyces_viscosus, GCF_000175315

Place names:
sample1_taxonomic, sample2_taxonomic, sample3_taxonomic...sample6_taxonomic, sample7_taxonomic



julia> metaphlan_profiles("test/files/metaphlan_multi_test.tsv", :genus)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 3 things in 7 places

Thing names:
Methanobrevibacter, Methanosphaera, Actinomyces

Place names:
sample1_taxonomic, sample2_taxonomic, sample3_taxonomic...sample6_taxonomic, sample7_taxonomic



julia> metaphlan_profiles("test/files/metaphlan_multi_test.tsv", 3)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 2 things in 7 places

Thing names:
Methanobacteria, Actinobacteria

Place names:
sample1_taxonomic, sample2_taxonomic, sample3_taxonomic...sample6_taxonomic, sample7_taxonomic



# julia> metaphlan_profiles("test/files/metaphlan_multi_test_unidentified.tsv")
# CommunityProfile{Float64, Taxon, MicrobiomeSample} with 43 things in 7 places

# Thing names:
# UNIDENTIFIED, Archaea, Euryarchaeota...Actinomyces_viscosus, GCF_000175315

# Place names:
# sample1_taxonomic, sample2_taxonomic, sample3_taxonomic...sample6_taxonomic, sample7_taxonomic



# julia> metaphlan_profiles("test/files/metaphlan_multi_test_unidentified.tsv", keepunidentified = true)
# CommunityProfile{Float64, Taxon, MicrobiomeSample} with 43 things in 7 places

# Thing names:
# UNIDENTIFIED, Archaea, Euryarchaeota...Actinomyces_viscosus, GCF_000175315

# Place names:
# sample1_taxonomic, sample2_taxonomic, sample3_taxonomic...sample6_taxonomic, sample7_taxonomic
```
"""
function metaphlan_profiles(path::AbstractString, level=:all; keepunidentified=false)
    profiles = CSV.read(path, DataFrame)
    taxa = [last(_split_clades(c)) for c in profiles[:, "#SampleID"]]
    mat = sparse(Matrix(profiles[:, 2:end]))
    samples = MicrobiomeSample.(replace.(names(profiles[:, 2:end]), Ref("_profile" => "")))
    if level == :all
        keep = Colon()
    elseif keepunidentified
        keep = [ismissing(c) || c == level for c in clade.(taxa)]
    else
        keep = [!ismissing(c) && c == level for c in clade.(taxa)]
    end
    return CommunityProfile(mat[keep, :], taxa[keep], samples)
end

function metaphlan_profiles(path::AbstractString, level::Int; keepunidentified=false)
    level = keys(taxonlevels)[level]
    metaphlan_profiles(path, level; keepunidentified)
end

"""
    metaphlan_profiles(paths::Array{<:AbstractString, 1}, level::Union{Int, Symbol}=:all)

Compiles MetaPhlAn profiles from multiple single tables into a CommunityProfile.
    
```jldoctest metaphlan_profiles

Examples
≡≡≡≡≡≡≡≡≡≡
julia> metaphlan_profiles(["test/files/metaphlan_single1.tsv", "test/files/metaphlan_single2.tsv"])
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 129 things in 2 places

Thing names:
Bacteria, Firmicutes, Bacteroidetes...Coprococcus_eutactus, Ruminococcus_bromii

Place names:
metaphlan_single1, metaphlan_single2



julia> metaphlan_profiles(["test/files/metaphlan_single1.tsv", "test/files/metaphlan_single2.tsv"], :genus)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 46 things in 2 places

Thing names:
Bacteroides, Roseburia, Faecalibacterium...Ruthenibacterium, Haemophilus

Place names:
metaphlan_single1, metaphlan_single2



julia> metaphlan_profiles(["test/files/metaphlan_single1.tsv", "test/files/metaphlan_single2.tsv"], 5)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 24 things in 2 places

Thing names:
Lachnospiraceae, Ruminococcaceae, Bacteroidaceae...Clostridiales_unclassified, Pasteurellaceae

Place names:
metaphlan_single1, metaphlan_single2
```
"""
function metaphlan_profiles(paths::Array{<:AbstractString, 1}, level=:all)
    profiles = []
    for path in paths 
        push!(profiles, metaphlan_profile(path, level;))
    end
    commjoin(profiles...)
end

function metaphlan_profiles(paths::Array{<:AbstractString, 1}, level::Int)
    level = keys(taxonlevels)[level]
    metaphlan_profiles(paths, level)
end
        
"""
    taxfilter!(df::DataFrame, level::Union{Int, Symbol}; keepunidentified::Bool)

Filter a MetaPhlAn table (as DataFrame) to a particular taxon level.
Levels may be given either as numbers or symbols:

- `1` = `:kingdom`
- `2` = `:phylum`
- `3` = `:class`
- `4` = `:order`
- `5` = `:family`
- `6` = `:genus`
- `7` = `:species`
- `8` = `:subspecies`

Taxon level is removed from resulting taxon string, eg.
`g__Bifidobacterium` becomes `Bifidobacterium`.

Set `keepunidentified` flag to `false` to remove `UNIDENTIFIED` rows.

`taxfilter!()` modifies the dataframe that you pass to it and `taxfilter()` doesn't.

This function will also rename the taxa in the first column.

```jldoctest taxfilter

Examples
≡≡≡≡≡≡≡≡≡≡
julia> df
4×2 DataFrame
 Row │ taxon                          abundance 
     │ String                         Float64   
─────┼──────────────────────────────────────────
   1 │ k__Bacteria                     100.0
   2 │ k__Bacteria|p__Firmicutes        63.1582
   3 │ k__Bacteria|p__Bacteroidetes     25.6038
   4 │ k__Bacteria|p__Actinobacteria    11.0898

julia> taxfilter(df,2; keepunidentified=true)
4×2 DataFrame
 Row │ taxon            abundance 
     │ String           Float64   
─────┼────────────────────────────
   1 │ Firmicutes         63.1582
   2 │ Bacteroidetes      25.6038
   3 │ Actinobacteria     11.0898
   4 │ Verrucomicrobia     0.1482

julia> df
4×2 DataFrame
 Row │ taxon                          abundance 
     │ String                         Float64   
─────┼──────────────────────────────────────────
   1 │ k__Bacteria                     100.0
   2 │ k__Bacteria|p__Firmicutes        63.1582
   3 │ k__Bacteria|p__Bacteroidetes     25.6038
   4 │ k__Bacteria|p__Actinobacteria    11.0898

julia> taxfilter!(df,2; keepunidentified=true)
3×2 DataFrame
 Row │ taxon           abundance 
     │ String          Float64   
─────┼───────────────────────────
   1 │ Firmicutes        63.1582
   2 │ Bacteroidetes     25.6038
   3 │ Actinobacteria    11.0898

julia> df
3×2 DataFrame
 Row │ taxon           abundance 
     │ String          Float64   
─────┼───────────────────────────
   1 │ Firmicutes        63.1582
   2 │ Bacteroidetes     25.6038
   3 │ Actinobacteria    11.0898

julia> taxfilter!(df,1; keepunidentified=true)
3×2 DataFrame
 Row │ taxon           abundance 
     │ String          Float64   
─────┼───────────────────────────
   1 │ Firmicutes        63.1582
   2 │ Bacteroidetes     25.6038
   3 │ Actinobacteria    11.0898
   
```
"""
function taxfilter!(taxonomic_profile::AbstractDataFrame, level::Int=7; keepunidentified=true)
    in(level, collect(1:8)) || @error "$level not a valid taxonomic level" taxonlevels
    
    taxonomic_profile[!, 1] = parsetaxon.(taxonomic_profile[!, 1]; throw_error=false)
    filter!(taxonomic_profile) do row
        cl = clade(row[1])
        keepunidentified ? ismissing(cl) || taxonlevels[cl] == level : level == taxonlevels[cl]
    end

    taxonomic_profile[!, 1] = map(name, taxonomic_profile[!, 1])
    return taxonomic_profile
end

function taxfilter!(taxonomic_profile::AbstractDataFrame, level::Symbol; keepunidentified=true)
    in(level, keys(taxonlevels)) || @error "$level not a valid taxonomic level" taxonlevels
    taxfilter!(taxonomic_profile, taxonlevels[level]; keepunidentified=keepunidentified)
end

function taxfilter(taxonomic_profile::AbstractDataFrame, level::Int=7; keepunidentified=true)
    filt = deepcopy(taxonomic_profile)
    taxfilter!(filt, level; keepunidentified=keepunidentified)
    return filt
end

function taxfilter(taxonomic_profile::AbstractDataFrame, level::Symbol; keepunidentified=true)
    filt = deepcopy(taxonomic_profile)
    taxfilter!(filt, level; keepunidentified=keepunidentified)
    return filt
end

"""
    parsetaxon(taxstring::AbstractString, taxlevel::Union{Int, Symbol})

Finds given taxonomic level in a string (as formatted by MetaPhlAn (eg "k__Bacteria|p__Proteobacteria...")) and returns the clade and taxonomic level as a Taxon.
If taxon level not given, function will return the most specific (lowest) taxonomic level available.

Levels may be given either as numbers or symbols:

- `1` = `:kingdom`
- `2` = `:phylum`
- `3` = `:class`
- `4` = `:order`
- `5` = `:family`
- `6` = `:genus`
- `7` = `:species`
- `8` = `:subspecies`

Examples
≡≡≡≡≡≡≡≡≡≡
 
```jldoctest parsetaxon
julia> parsetaxon("k__Archaea|p__Euryarchaeota|c__Methanobacteria", 2)
Taxon("Euryarchaeota", :phylum)

julia> parsetaxon("k__Archaea|p__Euryarchaeota|c__Methanobacteria", :kingdom)
Taxon("Archaea", :kingdom)

julia> parsetaxon("k__Archaea|p__Euryarchaeota|c__Methanobacteria")
Taxon("Methanobacteria", :class)
```
"""
function parsetaxon(taxstring::AbstractString; throw_error=true)
    taxa = parsetaxa(taxstring, throw_error=throw_error)
    return last(taxa)
end

function parsetaxon(taxstring::AbstractString, taxlevel::Int; throw_error=true)
    taxa = parsetaxa(taxstring, throw_error=throw_error)
    taxlevel <= length(taxa) || throw(ArgumentError("Taxonomy does not contain level $taxlevel"))
    return taxa[taxlevel]
end

parsetaxon(taxstring::AbstractString, taxlevel::Symbol) = parsetaxon(taxstring, taxonlevels[taxlevel])

"""
    parsetaxa(taxstring::AbstractString; throw_error=true)

Given a string representing taxonmic levels as formatted by MetaPhlAn (eg "k__Bacteria|p__Proteobacteria..."), separates taxonomic levels into elements of type Taxon in a vector.

Examples
≡≡≡≡≡≡≡≡≡≡

```jldoctest parsetaxa
julia> parsetaxa("k__Archaea|p__Euryarchaeota|c__Methanobacteria"; throw_error = true)
3-element Vector{Taxon}:
 Taxon("Archaea", :kingdom)
 Taxon("Euryarchaeota", :phylum)
 Taxon("Methanobacteria", :class)
```
"""
function parsetaxa(taxstring::AbstractString; throw_error=true)
    taxa = split(taxstring, '|')
    return map(t-> Taxon(t...), _shortname.(taxa, throw_error=throw_error))
end

function _shortname(taxon::AbstractString; throw_error=true)
    m = match(r"^[kpcofgst]__(\w+)$", taxon)  
    if isnothing(m)
        throw_error ? throw(ArgumentError("Improperly formated taxon $taxon")) : return (string(taxon), :unidentified)
    end
    return string(m.captures[1]), shortlevels[Symbol(first(taxon))]
end
