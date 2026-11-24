function _split_ranks(rank_string)
    ranks = split(rank_string, '|')
    taxa = Taxon[]
    for rank in ranks
        push!(taxa, taxon(rank))
    end
    return taxa
end

"""
    metaphlan_profile(path::AbstractString, rank::Union{Int, Symbol}=:all; sample)

Creates a CommunityProfile from a MetaPhlAn output file.
Can select data according to taxonomic rank. If rank not given, all data is used.
`sample` may be a name or an existing sample object with metadata. The default name
is the filename without table/compression suffixes. Plain, gzip, and XZ paths are
supported. Named headers select relative abundance independently of extra columns.

Levels may be given either as numbers or symbols:

- `1` = `:kingdom`
- `2` = `:phylum`
- `3` = `:class`
- `4` = `:order`
- `5` = `:family`
- `6` = `:genus`
- `7` = `:species`
- `8` = `:subspecies`
"""
function metaphlan_profile(path::AbstractString, rank = :all; sample = _source_name(path))
    profile = read_metaphlan(path)
    taxa = _terminal_taxon.(profile.feature)
    keep = rank == :all ? Colon() : [ismissing(c) || c == rank for c in taxrank.(taxa)]
    values = profile.abundance[keep]
    return CommunityProfile(sparse(reshape(values, length(values), 1)), taxa[keep], [_profile_sample(sample)])
end

function metaphlan_profile(path::AbstractString, rank::Int; sample = _source_name(path))
    rank = keys(Microbiome._ranks)[rank]
    return metaphlan_profile(path, rank; sample)
end

"""
    metaphlan_profiles(path::AbstractString, rank::Union{Int, Symbol}=:all; keepunidentified=false)

Reads in MetaPhlAn profiles from a merged table into a CommunityProfile.
Can select data according to taxonomic rank. If rank not given, all data is used.
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

"""
function metaphlan_profiles(path::AbstractString, rank = :all; samplestart = 2, keepunidentified = false, replace_string = "_profile")
    profiles = _csv_profile(path) do source
        CSV.read(source, Tables.columntable; comment = "#")
    end
    taxa = Taxon[_terminal_taxon(key) for key in profiles[1]]
    mat = reduce(hcat, [sparse(profiles[i]) for i in samplestart:length(profiles)])
    samples = collect(map(s -> MicrobiomeSample(replace(string(s), replace_string => "")), keys(profiles)[samplestart:end]))

    if rank == :all
        keep = Colon()
    elseif keepunidentified
        keep = [ismissing(c) || c == rank for c in taxrank.(taxa)]
    else
        keep = [!ismissing(c) && c == rank for c in taxrank.(taxa)]
    end
    return CommunityProfile(mat[keep, :], taxa[keep], samples)
end

function metaphlan_profiles(path::AbstractString, rank::Int; kwargs...)
    rank = keys(Microbiome._ranks)[rank + 1]
    return metaphlan_profiles(path, rank; kwargs...)
end

"""
    metaphlan_profiles(paths::AbstractVector{<:AbstractString}, rank::Union{Int, Symbol}=:all)

Combines MetaPhlAn profiles from multiple single tables into a CommunityProfile.
Samples follow path order, and features follow first occurrence. `samples` may
supply names or sample objects. Plain, gzip, and XZ files may be mixed. A shared
in-memory feature map builds one Float64 profile without intermediate profiles
or a persistent index. Missing-rank features remain included when filtering rank.
"""
function metaphlan_profiles(paths::AbstractVector{<:AbstractString}, rank = :all; samples = nothing)
    return _load_profiles(paths, MetaPhlAnFormat(rank); samples)
end

function metaphlan_profiles(paths::AbstractVector{<:AbstractString}, rank::Int; samples = nothing)
    rank = keys(Microbiome._ranks)[rank + 1]
    return metaphlan_profiles(paths, rank; samples)
end


"""
    parsetaxon(taxstring::AbstractString, rank::Union{Int, Symbol})

Finds given taxonomic rank in a string (as formatted by MetaPhlAn (eg "k__Bacteria|p__Proteobacteria..."))
and returns the name and taxonomic rank as a `Taxon`.
If taxon rank not given, function will return the most specific (lowest) taxonomic rank available.

Levels may be given either as numbers or symbols:

- `1` = `:kingdom`
- `2` = `:phylum`
- `3` = `:class`
- `4` = `:order`
- `5` = `:family`
- `6` = `:genus`
- `7` = `:species`
- `8` = `:subspecies`
"""
function parsetaxon(taxstring::AbstractString; throw_error = true)
    taxa = parsetaxa(taxstring, throw_error = throw_error)
    return last(taxa)
end

function parsetaxon(taxstring::AbstractString, rank::Int; throw_error = true)
    taxa = parsetaxa(taxstring, throw_error = throw_error)
    rank <= length(taxa) || throw(ArgumentError("Taxonomy does not contain rank $rank"))
    return taxa[rank]
end

parsetaxon(taxstring::AbstractString, rank::Symbol) = parsetaxon(taxstring, Microbiome._ranks[rank])

"""
    parsetaxa(taxstring::AbstractString; throw_error=true)

Given a string representing taxonmic ranks as formatted by MetaPhlAn (eg "k__Bacteria|p__Proteobacteria..."),
separates taxonomic ranks into elements of type Taxon in a vector.
"""
function parsetaxa(taxstring::AbstractString; throw_error = true)
    taxa = split(taxstring, '|')
    return map(t -> Taxon(t...), _shortname.(taxa, throw_error = throw_error))
end

function _shortname(taxon::AbstractString; throw_error = true)
    m = match(r"^[kpcofgst]__(\w+)$", taxon)
    if isnothing(m)
        throw_error ? throw(ArgumentError("Improperly formated taxon $taxon")) : return (string(taxon), :unidentified)
    end
    return string(m.captures[1]), Microbiome._shortranks[Symbol(first(taxon))]
end
