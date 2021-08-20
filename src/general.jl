
"""
    import_abundance_table(file::AbstractString; delim::Char='\t')

Given a file path or paths to abundance tables (eg humann2 or metaphlan2),
create abundance table. Table is presumed to have samples in columns and
features in rows. First column is taken as feature IDs.
"""
function import_abundance_table(file::AbstractString; delim::Char='\t')
    @info "Importing abundance table" file
    df = CSV.File(file, delim=delim) |> DataFrame
    rename!(df, names(df)[1] => :col1)
    return df
end

function import_abundance_tables(files::Array{<:AbstractString, 1}; delim::Char='\t')
    @info "Importing abundance tables"
    fulltable = DataFrame(col1=String[])
    for t in files
        df = import_abundance_table(t, delim=delim)
        fulltable = join(fulltable, df, on=:col1, kind=:outer)
    end

    # replace all missing values (from joins) with 0.
    fulltable = map(c -> eltype(c) <: Union{<:Number, Missing} ? collect(Missings.replace(c, 0)) : c, eachcol(fulltable))
    return fulltable
end


function clean_abundance_tables(files::Array{String, 1};
                        delim::Char='\t',
                        col1::Symbol=:taxon,
                        suffix::String="_taxonomic_profile")
    @info "Cleaning"
    t = import_abundance_tables(files, delim=delim)

    rename!(t, :col1 => col1)
    rename!(n-> Symbol(replace(String(n), suffix => "")), t)

    return t
end


"""
    rm_strat!(df::DataFrame; col::Union{Int, Symbol}=1)

Given an abundance table, makes a CommunityProfile that shows the total abundances at the kingdom taxonomic-level.
```jldoctest taxfilter
Examples
≡≡≡≡≡≡≡≡≡≡
julia> table
2×4 DataFrame
 Row │ taxname      sample1_taxonomic_profile  sample2_taxonomic_profile  sample3_taxonomic_profile  
     │ String       Float64                    Float64                    Float64                                      
─────┼───────────────────────────────────────────────────────────────────────────────────────────────
   1 │ taxa1                         0.0                        0.0                   14.13558                                              
   2 │ taxa2                       100.0                      100.0                          0                             

julia> rm_strat!(table)
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 2 things in 3 places
   
Thing names:
taxa1, taxa2
   
Place names:
sample1_taxonomic_profile, sample2_taxonomic_profile, sample3_taxonomic_profile
   
```
"""
function rm_strat!(df::DataFrame; col::Union{Int, Symbol}=1)
    table=filter!(row->!occursin(r"\|", row[1]), df)
    mat = Matrix(select(table, Not(col)))
    tax = [parsetaxon.(str) for str in table.col]
    mss = MicrobiomeSample.(names(table)[2:end])
    comm = CommunityProfile(sparse(mat), tax , mss)
end


"""
    permanova(dm::Array{<:Real,2}, metadata::AbstractVector, nperm::Int=999;
                label=nothing, datafilter=x->true)
    permanova(dm::Array{<:Real,2}, metadata::AbstractDataFrame, nperm=999;
                fields=names(metadata), kwargs...)

Performs PERMANOVA analysis from R's [`vegan`](https://www.rdocumentation.org/packages/vegan/versions/2.4-2) package
using the `adonis` function.

**Positional arguments**:

- `dm`: a symetric distance matrix.
- `metadata`: either a vector of numerical or categorical data to test against,
  or a DataFrame with columns for each variable to test against.
  Any missing data in the vector or rows of the DataFrame with missing data
  will be filtered out.
- `nperm`=999: number of permutations for PERMANOVA.

**Keyword Arguments**:

- `datafilter=x-> true`: a function to filter elements (or rows) of `metadata`.
  Removal of missing values occurs before this function is applied.
- `label=nothing`: If provided, adds a column `label` to the results
  filled with this value.
  Useful if performing multiple runs that will be combined in a single DataFrame.
- `fields`: if passing a DataFrame as `metadata`,
  an array of symbols may be passed to select only certain columns
  and/or determine their order for the resulting PERMANOVA.

Note: this will throw an error if `vegan` is not installed.
To install:

```julia
using RCall

reval("install.packages('vegan')")
```
"""
function permanova(dm::Array{<:Real,2}, metadata::AbstractVector, nperm::Int=999;
                    datafilter=x->true, label=nothing)
    size(dm,1) != size(dm,2) && throw(ArgumentError("dm must be symetrical distance matrix"))
    size(dm,2) != length(metadata) && throw(ArgumentError("Metadata does not match the size of distance matrix"))
    let notmissing = map(!ismissing, metadata)
        metadata = metadata[notmissing]
        dm = dm[notmissing, notmissing]
    end

    filt = map(datafilter, metadata)
    r_dm = dm[filt, filt]
    metadata = metadata[filt]
    @rput r_dm
    @rput metadata
    reval("library(vegan)")

    reval("p <- adonis(r_dm ~ metadata, permutations = $nperm)")

    @rget p

    p = p[:aov_tab]
    if !isnothing(label)
        p[!,:label] = fill(label, size(p, 1))
    end

    return p
end


function permanova(dm::Array{<:Real,2}, metadata::AbstractDataFrame, nperm=999;
            datafilter=x->true,
            label=nothing,
            fields=names(metadata))

    let notmissing = map(row->all(!ismissing, row[fields]), eachrow(metadata))
        metadata = metadata[notmissing, :]
        dm = dm[notmissing, notmissing]
    end

    fields = join(String.(fields), " + ")

    filt = map(datafilter, eachrow(metadata))
    r_meta = metadata[filt, :]
    r_dm = dm[filt,filt]
    @rput r_meta
    @rput r_dm
    reval("library(vegan)")
    reval("p <- adonis(r_dm ~ $fields, data=r_meta, permutations = $nperm)")

    @rget p
    p = p[:aov_tab]
    if !isnothing(label)
        p[!,:label] = fill(label, size(p, 1))
    end

    return p
end
