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

`taxfilter!()` modifies the dataframe that you pass to it and `taxfilter()` doesn't.

```jldoctest taxfilter! and taxfilter

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
    
    taxonomic_profile[!, 1] = last.(parsetaxa.(taxonomic_profile[!, 1]; throw=false))
    filter!(taxonomic_profile) do row
        tlev = taxonlevels[row[1][2]]
        keepunidentified ? in(tlev, (0, level)) : level == tlev
    end

    taxonomic_profile[!, 1] = map(t-> t[1], taxonomic_profile[!, 1])
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

Levels may be given either as numbers or symbols:

- `1` = `:Kingdom`
- `2` = `:Phylum`
- `3` = `:Class`
- `4` = `:Order`
- `5` = `:Family`
- `6` = `:Genus`
- `7` = `:Species`
- `8` = `:Subspecies`

```jldoctest parsetaxon
Examples
≡≡≡≡≡≡≡≡≡≡

 julia> parsetaxa("k__Archaea|p__Euryarchaeota|c__Methanobacteria";throw = true)
 3-element Vector{Tuple{String, Symbol}}:
 ("Archaea", :kingdom)
 ("Euryarchaeota", :phylum)
 ("Methanobacteria", :class)

```

"""
function parsetaxon(taxstring::AbstractString, taxlevel::Int=7; throw=true)
    taxa = parsetaxa(taxstring, throw=throw)
    length(taxa) <= taxlevel || throw(ArgumentError("Taxonomy does not contain level $taxlevel"))

    return taxa[taxlevel]
end

parsetaxon(taxstring::AbstractString, taxlevel::Symbol) = parsetaxon(taxstring, taxonlevels[taxlevel])

function parsetaxa(taxstring::AbstractString; throw=true)
    taxa = split(taxstring, '|')
    return shortname.(taxa, throw=throw)
end

function shortname(taxon::AbstractString; throw=true)
    m = match(r"[kpcofgst]__(\w+)", taxon)  
    
    if isnothing(m)
        throw ? throw(ArgumentError("Improperly formated taxon $taxon")) : return (string(taxon), :unidentified)
    end

    return (string(m.captures[1]), shortlevels[Symbol(first(taxon))])
end

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
"""
                    
function gettaxon(elt)
           pieces = split(elt, "__")
           length(pieces) == 2 || error("incorrectly formatted name string: $elt")
           (lev, name) = pieces
           lev_abr = Symbol(lev)
           lev_abr in keys(shortlevels) || error("Invalid taxon abbreviation: $lev_abr in name $elt")
           return Taxon(name, shortlevels[lev_abr])
       end

function findclade(taxstring, taxlevel)
    splitStr = split(taxstring, "|")
    for elt in splitStr
        t = gettaxon(elt)
        if taxlevel == clade(t)
            return t
        end
    end
end