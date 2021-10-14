#============
MetaPhlAn CLI
============#

"""
    metaphlan(inputfile, outputfile; kwargs...)

Run `metaphlan` command line tool on `inputfile`,
creating `outputfile`.
Requires `metaphlan` to be installed and accessible in the `PATH`
(see [Getting Started](@ref)).

`metaphlan` options can be passed via keyword arguments.
For example, if on the command line you would run:

```sh
\$ metaphlan some.fastq.gz output/some_profile.tsv --input_type fastq --nprocs 8
```

using this function, you would write:

```julia
metaphlan("some.fastq.gz", "output/some_profile.tsv"; input_type="fastq", nprocs=8)
```

Note: the `input_type` keyword is required.

Set the environmental variable "METAPHLAN_BOWTIE2_DB"
to specify the location where the markergene database is/will be installed,
or pass `bowtie2db = "some/path"` as a keyword argument.
"""
function metaphlan(inputfile, output; kwargs...)
    check_for_install("metaphlan")
    cmd = ["metaphlan", inputfile, output]
    add_cli_kwargs!(cmd, kwargs)
    
    if !haskey(kwargs, :bowtie2db) && haskey(ENV, "METAPHLAN_BOWTIE2_DB")
        append!(cmd, ["--bowtie2db", ENV["METAPHLAN_BOWTIE2_DB"]])
    end

    deleteat!(cmd, findall(==(""), cmd))
    @info "Running command: $(Cmd(cmd))"
    return run(Cmd(cmd))
end

"""
    metaphlan_merge(paths, outputfile; kwargs...)

Run `merge_metaphlan_tables` command line tool on the files in `paths`,
creating `outputfile`.
Requires `metaphlan` to be installed and accessible in the `PATH`
(see [Getting Started](@ref)).
"""
function metaphlan_merge(paths, output; kwargs...)
    check_for_install("merge_metaphlan_tables.py")
    cmd = ["merge_metaphlan_tables.py", "-o", output]
    for (key,val) in pairs(kwargs)
        if val isa Bool
            val && push!(cmd, replace(string("--", key), "_"=>"-"))
        elseif val isa AbstractVector
            append!(cmd, [replace(string("--", key), "_"=>"-"), string.(val)...])
        else
            append!(cmd, [replace(string("--", key), "_"=>"-"), string(val)])
        end
    end
    append!(cmd, paths)
    run(Cmd(cmd))
end


#==============
MetaPhlAn Utils
==============#

function _split_ranks(rank_string)
    ranks = split(rank_string, '|')
    taxa = Taxon[]
    for rank in ranks
        push!(taxa, taxon(rank))
    end
    return taxa
end

"""
    metaphlan_profile(path::AbstractString, rank::Union{Int, Symbol}=:all; sample::AbstractString=basename(first(splitext(path))))

Compiles a MetaPhlAn file into a CommunityProfile.
Can select data according to taxonomic rank. If rank not given, all data is compiled.
`Sample name` of the CommunityProfile can be specified by passing a `sample` argument. If name not given, the name of the file becomes the `Sample name`.

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
function metaphlan_profile(path::AbstractString, rank=:all; sample=basename(first(splitext(path))))
    if startswith(first(eachline(path)), "#")
        dr = 5
        hd = ["taxon", "NCBI_taxid", "abundance", "additional_species"]
    else
        dr = 2
        hd = ["taxon", "abundance"]
    end
    profile = CSV.read(path, skipto=dr, header=hd, Tables.columntable)
    taxa = [last(_split_ranks(c)) for c in profile.taxon]
    mat = sparse(reshape(profile.abundance, length(profile.abundance), 1))
    sample = sample isa Microbiome.AbstractSample ? sample : MicrobiomeSample(sample)
    keep = rank == :all ? Colon() : [ismissing(c) || c == rank for c in taxrank.(taxa)]
    return CommunityProfile(mat[keep, :], taxa[keep], [sample])
end

function metaphlan_profile(path::AbstractString, rank::Int; sample=basename(first(splitext(path))))
    rank = keys(Microbiome._ranks)[rank]
    metaphlan_profile(path, rank; sample)
end

"""
    metaphlan_profiles(path::AbstractString, rank::Union{Int, Symbol}=:all; keepunidentified=false)

Compiles MetaPhlAn profiles from a merged table into a CommunityProfile.
Can select data according to taxonomic rank. If rank not given, all data is compiled.
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
function metaphlan_profiles(path::AbstractString, rank=:all; samplestart = 2, keepunidentified=false, replace_string="_profile")
    profiles = CSV.read(path, Tables.columntable; comment="#")
    taxa = [last(_split_ranks(c)) for c in profiles[1]]
    mat = reduce(hcat, [sparse(profiles[i]) for i in samplestart:length(profiles)])
    samples = collect(map(s-> MicrobiomeSample(replace(string(s), replace_string => "")), keys(profiles)[samplestart:end]))
    
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
    metaphlan_profiles(path, rank; kwargs...)
end

"""
    metaphlan_profiles(paths::Array{<:AbstractString, 1}, rank::Union{Int, Symbol}=:all)

Compiles MetaPhlAn profiles from multiple single tables into a CommunityProfile.
```
"""
function metaphlan_profiles(paths::Array{<:AbstractString, 1}, rank=:all; samples=nothing)
    if isnothing(samples)
        samples = [first(splitext(basename(f))) for f in paths]
    else
        length(samples) == length(paths) || throw(ArgumentError("Number of paths ($(length(paths))) and number of samples ($(length(samples))) does not match"))
    end
    profiles = []
    for (path, sample) in zip(paths, samples)
        push!(profiles, metaphlan_profile(path, rank; sample))
    end
    commjoin(profiles...)
end

function metaphlan_profiles(paths::Array{<:AbstractString, 1}, rank::Int; samples=nothing)
    rank = keys(Microbiome._ranks)[rank + 1]
    metaphlan_profiles(paths, rank; samples)
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
function parsetaxon(taxstring::AbstractString; throw_error=true)
    taxa = parsetaxa(taxstring, throw_error=throw_error)
    return last(taxa)
end

function parsetaxon(taxstring::AbstractString, rank::Int; throw_error=true)
    taxa = parsetaxa(taxstring, throw_error=throw_error)
    rank <= length(taxa) || throw(ArgumentError("Taxonomy does not contain rank $rank"))
    return taxa[rank]
end

parsetaxon(taxstring::AbstractString, rank::Symbol) = parsetaxon(taxstring, Microbiome._ranks[rank])

"""
    parsetaxa(taxstring::AbstractString; throw_error=true)

Given a string representing taxonmic ranks as formatted by MetaPhlAn (eg "k__Bacteria|p__Proteobacteria..."),
separates taxonomic ranks into elements of type Taxon in a vector.
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
    return string(m.captures[1]), Microbiome._shortranks[Symbol(first(taxon))]
end
