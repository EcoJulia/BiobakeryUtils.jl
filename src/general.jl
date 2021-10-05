"""
    permanova(dm::Array{<:Real,2}, metadata::AbstractVector, nperm::Int=999;
                label=nothing, datafilter=x->true)
    permanova(dm::Array{<:Real,2}, metadata::AbstractTable, nperm=999;
                fields=names(metadata), kwargs...)

Performs PERMANOVA analysis from R's [`vegan`](https://www.rdocumentation.org/packages/vegan/versions/2.4-2) package
using the `adonis` function.

**Positional arguments**:

- `dm`: a symetric distance matrix.
- `metadata`: either a vector of numerical or categorical data to test against,
  or a Table with columns for each variable to test against.
  Any missing data in the vector or rows of the Table with missing data
  will be filtered out.
- `nperm`=999: number of permutations for PERMANOVA.

**Keyword Arguments**:

- `datafilter=x-> true`: a function to filter elements (or rows) of `metadata`.
  Removal of missing values occurs before this function is applied.
- `label=nothing`: If provided, adds a column `label` to the results
  filled with this value.
  Useful if performing multiple runs that will be combined in a single Table.
- `fields`: if passing a Table as `metadata`,
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
