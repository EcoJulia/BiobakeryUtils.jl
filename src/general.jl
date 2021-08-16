
"""
    import_abundance_table(file::AbstractString; delim::Char='\t')

Given a file path (eg humann2 or metaphlan2), creates an abundance table. 
A table is presumed to have samples in columns and features in rows. 
First column is taken as feature IDs.
```jldoctest taxfilter
Examples
≡≡≡≡≡≡≡≡≡≡
julia> abund = import_abundance_table("filename.tsv")
┌ Info: Importing abundance table
└   file = "filename.tsv"
1×1 DataFrame
 Row │ colname                              
     │ String                            
─────┼────────────────────────────────────────────────────────
   1 │ k__Bacteria
```
"""
function import_abundance_table(file::AbstractString; delim::Char='\t')
    @info "Importing abundance table" file
    df = CSV.File(file, delim=delim) |> DataFrame
    rename!(df, names(df)[1] => :col1)
    return df
end

"""
    import_abundance_tables(files::Array{<:AbstractString, 1}; delim::Char='\t')

Given file paths (eg humann2 or metaphlan2), create abundance table. 
A table is presumed to have samples in columns and features in rows. 
First column is taken as feature IDs.
```jldoctest taxfilter
Examples
≡≡≡≡≡≡≡≡≡≡
julia> abund = import_abundance_tables(["filename1.tsv", "filename2.tsv"])
[ Info: Importing abundance tables
┌ Info: Importing abundance table
└   file = "filename1.tsv"
┌ Info: Importing abundance table
└   file = "filename2.tsv"
2×1 DataFrame
 Row │ col1                              
     │ String                            
─────┼───────────────────────────────────
   1 │ k__Bacteria
   2 │ k__Archaea
```
"""

function import_abundance_tables(files::Array{<:AbstractString, 1}; delim::Char='\t')
    @info "Importing abundance tables"
    fulltable = DataFrame(col1=String[])
    for t in files
        df = import_abundance_table(t, delim=delim)
        # Qn: kept getting the "ERROR: LoadError: ArgumentError: join function for data frames is not supported" 
        # Changed join to outerjoin and removed kind=:outer (changed line 59 into line 60)
        # fulltable = join(fulltable, df, on=:col1, kind=:outer) 
        fulltable = outerjoin(fulltable, df, on=:col1)
    end

    # replace all missing values (from joins) with 0.
    fulltable = map(c -> eltype(c) <: Union{<:Number, Missing} ? collect(Missings.replace(c, 0)) : c, eachcol(fulltable)) # Qn: this turns the table into a vector - not sure if this is how it should work
    return fulltable
end

"""
    clean_abundance_tables(files::Array{String, 1};
                            delim::Char='\t',
                            col1::Symbol=:taxon,
                            suffix::String="_taxonomic_profile")
                            
Given file paths (eg humann2 or metaphlan2), renames tables. 
A table is presumed to have samples in columns and features in rows.
```jldoctest taxfilter
Examples
≡≡≡≡≡≡≡≡≡≡
julia> clean = clean_abundance_tables(["filename1.tsv", "filename2.tsv"])


```
"""

function clean_abundance_tables(files::Array{String, 1};
                        delim::Char='\t',
                        col1::Symbol=:taxon,
                        suffix::String="_taxonomic_profile")
    @info "Cleaning"
    t = import_abundance_tables(files, delim=delim) 
    # since import_abundance_tables returns a vector, this gives the "ERROR: MethodError: no method matching rename!(::Vector{Vector{String}}, ::Pair{Symbol, Symbol})"

    rename!(t, :col1 => col1)
    rename!(n-> Symbol(replace(String(n), suffix => "")), t)

    return t
end

"""
    rm_strat!(df::DataFrame; col::Union{Int, Symbol}=1)

Given an abundance table, classifies each feature into its own row.
```jldoctest taxfilter
Examples
≡≡≡≡≡≡≡≡≡≡
julia> t = import_abundance_table("filename.tsv")
┌ Info: Importing abundance table
└   file = "filename.tsv"
1×1 DataFrame
 Row │ col1                               sample1_taxonomic_profile 
     │ String                             Float64                   
─────┼────────────────────────────────────────────────────────────────────────────────
   1 │ k__Archaea                                           0.0
julia> rm_strat!(t)
1×1 DataFrame
 Row │ col1         sample1_taxonomic_profile  sample2_taxonomic_profile  sample3_taxonomic_profile  sample4_taxonomic_profile  sample5_taxonomic_profile  sample6_taxonomic_profile  sample7_t ⋯
     │ String       Float64                    Float64                    Float64                    Float64                    Float64                    Float64                    Float64   ⋯
─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ k__Archaea                         0.0                        0.0                     0.0                        0.0                           0.0                     0.0               ⋯
```
"""

function rm_strat!(df::DataFrame; col::Union{Int, Symbol}=1)
    filter!(row->!occursin(r"\|", row[1]), df)
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
#==============
PanPhlAn Utils
==============#

function panphlan_calcs(df::DataFrame)
    abun = abundancetable(df)
    dm = pairwise(Jaccard(), abun, dims=2)
    rowdm = pairwise(Jaccard(), abun, dims=1)
    col_clust = hclust(dm, :single)
    row_clust = hclust(rowdm, :single)
    optimalorder!(col_clust, dm)
    optimalorder!(row_clust, rowdm)

    mds = fit(MDS, dm, distances=true)

    return abun, dm, col_clust, row_clust, mds
end
