
"""
Given a file path or paths to abundance tables (eg humann2 or metaphlan2),
create abundance table. Table is presumed to have samples in columns and
features in rows. First column is taken as feature IDs.
"""
function import_abundance(path::String; delim='\t')
    df = CSV.read(path, delim=delim)
    for n in names(df)
        df[n] = coalesce.(df[n], 0)
    end

    return df
end

function import_abundance(paths::Array{String,1}; delim='\t')
    df = DataFrame(SampleID=String[])
    for f in paths
        df = CSV.read(f, delim=delim)
        rename!(df, names(df[1]), :feature)
        df = join(df, df, on=:feature, kind=:outer)
    end

    for n in names(df)
        df[n] = coalesce.(df[n], 0)
    end

    return df
end


"""
Given a dataframe with a column that has a pvalue column, perform
Benjamini Hochberch correction to generate q value column with given Q.
"""
function qvalue!(df::DataFrame, q::Float64=0.2; pcol::Symbol=:p_value, qcol::Symbol=:q_value)
    if eltype(df[pcol]) <:StatsBase.PValue
        ranks = invperm(sortperm(map(x->x.v,df[pcol])))
    else
        ranks = invperm(sortperm(map(x->x,df[pcol])))
    end
    m = length(ranks)
    df[qcol] = [i / m * q for i in eachindex(df[pcol])]
end

#==============
PanPhlAn Utils
==============#

function panphlan_calcs(df::DataFrame)
    abun = abundancetable(df)
    dm = getdm(df, Jaccard())
    rowdm = getrowdm(df, Jaccard())
    col_clust = hclust(dm.dm, :single)
    row_clust = hclust(rowdm.dm, :single)
    optimalorder!(col_clust, dm.dm)
    optimalorder!(row_clust, rowdm.dm)

    pco = pcoa(dm)

    return abun, dm, col_clust, row_clust, pco
end
