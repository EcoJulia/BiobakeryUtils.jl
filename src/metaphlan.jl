#============
MetaPhlAn CLI
============#

"""
    metaphlan(inputfile, output; kwargs...)

Run `metaphlan` command line tool on `inputfile`,
putting outputs in `output`.
Requires `metaphlan` to be installed and accessible in the `PATH`
(see [Getting Started](@ref)).

`metaphlan` options can be passed via keyword arguments.
For example, if on the command line you would run:

```sh
\$ metaphlan some.fastq.gz output/ --input_type fastq --nprocs 8
```

using this function, you would write:

```julia
metaphlan("some.fastq.gz", "output/"; input_type="fastq", nprocs=8)
```

Note: the `input_type` keyword is required.

Set the environmental variable "METAPHLAN_BOWTIE2_DB"
to specify the location where the markergene database is/will be installed,
or pass `bowtie2db = "some/path"` as a keyword argument.
"""
function metaphlan(inputfile, output; kwargs...)
    c = ["metaphlan", inputfile, output]
    append!(c, Iterators.flatten((string("--", k), v) for (k,v) in pairs(kwargs)))
    
    if !haskey(kwargs, :bowtie2db) && haskey(ENV, "METAPHLAN_BOWTIE2_DB")
        append!(c, ["--bowtie2db", ENV["METAPHLAN_BOWTIE2_DB"]])
    end

    deleteat!(c, findall(==(""), c))
    @info "Running command: $(Cmd(c))"
    return run(Cmd(c))
end


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

```jldoctest metaphlan_profile

Examples
≡≡≡≡≡≡≡≡≡≡
julia> metaphlan_profile("test/files/metaphlan_single2.tsv")
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 96 features in 1 samples

Feature names:
Bacteria, Archaea, Firmicutes...Ruminococcus_bromii, Bacteroides_vulgatus

Sample names:
metaphlan_single2



julia> metaphlan_profile("test/files/metaphlan_single2.tsv", 4)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 11 features in 1 samples

Feature names:
Clostridiales, Bacteroidales, Coriobacteriales...Firmicutes_unclassified, Pasteurellales

Sample names:
metaphlan_single2



julia> metaphlan_profile("test/files/metaphlan_single2.tsv", :genus)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 40 features in 1 samples

Feature names:
Prevotella, Roseburia, Faecalibacterium...Haemophilus, Lactococcus

Sample names:
metaphlan_single2



julia> metaphlan_profile("test/files/metaphlan_single2.tsv", :genus, sample = "sample2")
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 40 features in 1 samples

Feature names:
Prevotella, Roseburia, Faecalibacterium...Haemophilus, Lactococcus

Sample names:
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
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 42 features in 7 samples

Feature names:
Archaea, Euryarchaeota, Methanobacteria...Actinomyces_viscosus, GCF_000175315

Sample names:
sample1_taxonomic, sample2_taxonomic, sample3_taxonomic...sample6_taxonomic, sample7_taxonomic



julia> metaphlan_profiles("test/files/metaphlan_multi_test.tsv", :genus)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 3 features in 7 samples

Feature names:
Methanobrevibacter, Methanosphaera, Actinomyces

Sample names:
sample1_taxonomic, sample2_taxonomic, sample3_taxonomic...sample6_taxonomic, sample7_taxonomic



julia> metaphlan_profiles("test/files/metaphlan_multi_test.tsv", 3)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 2 features in 7 samples

Feature names:
Methanobacteria, Actinobacteria

Sample names:
sample1_taxonomic, sample2_taxonomic, sample3_taxonomic...sample6_taxonomic, sample7_taxonomic


julia> metaphlan_profiles("test/files/metaphlan_multi_test_unidentified.tsv")
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 43 features in 7 samples

Feature names:
UNIDENTIFIED, Archaea, Euryarchaeota...Actinomyces_viscosus, GCF_000175315

Sample names:
sample1_taxonomic, sample2_taxonomic, sample3_taxonomic...sample6_taxonomic, sample7_taxonomic



# julia> metaphlan_profiles("test/files/metaphlan_multi_test_unidentified.tsv", keepunidentified = true)
# CommunityProfile{Float64, Taxon, MicrobiomeSample} with 43 features in 7 samples

# Feature names:
# UNIDENTIFIED, Archaea, Euryarchaeota...Actinomyces_viscosus, GCF_000175315

# Sample names:
# sample1_taxonomic, sample2_taxonomic, sample3_taxonomic...sample6_taxonomic, sample7_taxonomic
```
"""
function metaphlan_profiles(path::AbstractString, level=:all; keepunidentified=false, replace_string="_profile")
    profiles = CSV.read(path, Tables.columntable)
    taxa = [last(_split_clades(c)) for c in profiles[Symbol("#SampleID")]]
    mat = reduce(hcat, [sparse(profiles[k]) for k in keys(profiles)[2:end]])
    samples = collect(map(s-> MicrobiomeSample(replace(string(s), replace_string => "")), keys(profiles)[2:end]))
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
    
Examples
≡≡≡≡≡≡≡≡≡≡

```jldoctest metaphlan_profiles
julia> metaphlan_profiles(["test/files/metaphlan_single1.tsv", "test/files/metaphlan_single2.tsv"])
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 129 features in 2 samples

Feature names:
Bacteria, Firmicutes, Bacteroidetes...Coprococcus_eutactus, Ruminococcus_bromii

Sample names:
metaphlan_single1, metaphlan_single2



julia> metaphlan_profiles(["test/files/metaphlan_single1.tsv", "test/files/metaphlan_single2.tsv"], :genus)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 46 features in 2 samples

Feature names:
Bacteroides, Roseburia, Faecalibacterium...Ruthenibacterium, Haemophilus

Sample names:
metaphlan_single1, metaphlan_single2



julia> metaphlan_profiles(["test/files/metaphlan_single1.tsv", "test/files/metaphlan_single2.tsv"], 5)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 24 features in 2 samples

Feature names:
Lachnospiraceae, Ruminococcaceae, Bacteroidaceae...Clostridiales_unclassified, Pasteurellaceae

Sample names:
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
