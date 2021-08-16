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
    t = :subspecies)

function _split_clades(clade_string)
    clades = split(clade_string, '|')
    taxa = Taxon[]
    for clade in clades
        (level, name) = split(clade, "__")
        push!(taxa, Taxon(name, shortlevels[Symbol(level)]))
    end
    return taxa
end

function metaphlan_profile(path::AbstractString; sample=basename(first(splitext(path))), level=:all)
    profile = CSV.read(path, datarow=5, header=["clade", "NCBI_taxid", "abundance", "additional_species"], Tables.columntable)
    taxa = [last(_split_clades(c)) for c in profile.clade]
    mat = sparse(reshape(profile.abundance, length(profile.abundance), 1))
    sample = sample isa Microbiome.AbstractSample ? sample : MicrobiomeSample(sample)
    keep = level == :all ? Colon() : [ismissing(c) || c == level for c in clade.(taxa)]
    return CommunityProfile(mat[keep, :], taxa[keep], [sample])
end


"""
Option1: take a path to merged table (eg test/files/metaphlan_multi_profile.tsv)
    and make CommunityProfile
Option2: take vector of paths to single tables (eg ["test/files/metaphlan_single1_profile.tsv", "test/files/metaphlan_single2_profile.tsv"])
    and make CommunityProfile
"""
function metaphlan_profiles(tables)
end
        
"""
    taxfilter!(df::DataFrame, level::Union{Int, Symbol}; keepunidentified::Bool)
Filter a MetaPhlAn table (as DataFrame) to a particular taxon level.
Levels may be given either as numbers or symbols:
- `1` = `:Kingdom`
- `2` = `:Phylum`
- `3` = `:Class`
- `4` = `:Order`
- `5` = `:Family`
- `6` = `:Genus`
- `7` = `:Species`
- `8` = `:Subspecies`
Taxon level is removed from resulting taxon string, eg.
`g__Bifidobacterium` becomes `Bifidobacterium`.
Set `keepunidentified` flag to `false` to remove `UNIDENTIFIED` rows.

`taxfilter!()` modifies the dataframe.

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

"""
    taxfilter(df::DataFrame, level::Union{Int, Symbol}; keepunidentified::Bool)
Filter a MetaPhlAn table (as DataFrame) to a particular taxon level.
Levels may be given either as numbers or symbols:
- `1` = `:Kingdom`
- `2` = `:Phylum`
- `3` = `:Class`
- `4` = `:Order`
- `5` = `:Family`
- `6` = `:Genus`
- `7` = `:Species`
- `8` = `:Subspecies`
Taxon level is removed from resulting taxon string, eg.
`g__Bifidobacterium` becomes `Bifidobacterium`.
Set `keepunidentified` flag to `false` to remove `UNIDENTIFIED` rows.

`taxfilter()` doesn't modify the dataframe that you pass to it.

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
3×2 DataFrame
 Row │ taxon            abundance 
     │ String           Float64   
─────┼────────────────────────────
   1 │ Firmicutes         63.1582
   2 │ Bacteroidetes      25.6038
   3 │ Actinobacteria     11.0898
   
julia> df
4×2 DataFrame
 Row │ taxon                          abundance 
     │ String                         Float64   
─────┼──────────────────────────────────────────
   1 │ k__Bacteria                     100.0
   2 │ k__Bacteria|p__Firmicutes        63.1582
   3 │ k__Bacteria|p__Bacteroidetes     25.6038
   4 │ k__Bacteria|p__Actinobacteria    11.0898   
```
"""
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

    Levels may be given either as numbers or symbols:

- `1` = `:Kingdom`
- `2` = `:Phylum`
- `3` = `:Class`
- `4` = `:Order`
- `5` = `:Family`
- `6` = `:Genus`
- `7` = `:Species`
- `8` = `:Subspecies`

Examples
≡≡≡≡≡≡≡≡≡≡
 
```jldoctest parsetaxon
julia> parsetaxon("k__Archaea|p__Euryarchaeota|c__Methanobacteria", 2)
Taxon("Euryarchaeota", :phylum)

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

function _shortname(taxon::AbstractString; throw_error=true)
    m = match(r"^[kpcofgst]__(\w+)$", taxon)  
    if isnothing(m)
        throw_error ? throw(ArgumentError("Improperly formated taxon $taxon")) : return (string(taxon), :unidentified)
    end
    return string(m.captures[1]), shortlevels[Symbol(first(taxon))]
end

import BiobakeryUtils.parsetaxa
"""
    parsetaxa(taxstring::AbstractString; throw_error::Bool)

- `1` = `:Kingdom`
- `2` = `:Phylum`
- `3` = `:Class`
- `4` = `:Order`
- `5` = `:Family`
- `6` = `:Genus`
- `7` = `:Species`
- `8` = `:Subspecies`

Examples
≡≡≡≡≡≡≡≡≡≡

```jldoctest parsetaxa
julia> parsetaxa("k__Archaea|p__Euryarchaeota|c__Methanobacteria"; throw_error = true)
3-element Vector{Tuple{String, Symbol}}:
Taxon("Archaea", :kingdom)
Taxon("Euryarchaeota", :phylum)
Taxon("Methanobacteria", :class)
```
"""
function parsetaxa(taxstring::AbstractString; throw_error=true)
    taxa = split(taxstring, '|')
    return map(t-> Taxon(t...), _shortname.(taxa, throw_error=throw_error))
end
# Question? 
# I kept getting an "ERROR: error in method definition: function BiobakeryUtils.parsetaxa must be explicitly imported to be extended"
# And I resolved it by running import BiobakeryUtils.parsetaxa in the terminal
# Why did this error only come on this function and not the others? 

"""
    findclade(taxstring::AbstractString, taxlevel::Union{Symbol})

    Takes string and taxa level as arguments finds level in string:
    k = :kingdom,
    p = :phylum,
    c = :class,
    o = :order,
    f = :family,
    g = :genus,
    s = :species,
    t = :subspecies)

Examples
≡≡≡≡≡≡≡≡≡≡
 
```jldoctest findclade
julia> findclade("k__Archaea|p__Euryarchaeota|c__Methanobacteria", :kingdom)
Taxon("Archaea", :kingdom)
```
"""
function findclade(taxstring, taxlevel)
    splitStr = split(taxstring, "|")
    for elt in splitStr
        t = gettaxon(elt)
        if taxlevel == clade(t)
            return t
        end
    end
end

function gettaxon(elt)
    pieces = split(elt, "__")
    length(pieces) == 2 || error("incorrectly formatted name string: $elt")
    (lev, name) = pieces
    lev_abr = Symbol(lev)
    lev_abr in keys(shortlevels) || error("Invalid taxon abbreviation: $lev_abr in name $elt")
    return Taxon(name, shortlevels[lev_abr])
end