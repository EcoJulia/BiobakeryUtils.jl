
"""
Given a file path or paths to abundance tables (eg humann2 or metaphlan2),
create abundance table. Table is presumed to have samples in columns and
features in rows. First column is taken as feature IDs.
"""
function import_abundance_table(file::AbstractString; delim::Char='\t')
    @info "importing abundance table" file
    df = CSV.read(file, delim=delim, rows_for_type_detect=5000)
    rename!(df, names(df)[1] => :col1)
    return df
end


function import_abundance_tables(files::Array{<:AbstractString, 1}; delim::Char='\t')
    @info "importing abundance tables"
    fulltable = DataFrame(col1=String[])
    for t in files
        df = import_abundance_table(t, delim=delim)
        fulltable = join(fulltable, df, on=:col1, kind=:outer)
    end

    # replace all missing values (from joins) with 0.
    fulltable = map(c -> eltype(c) <: Number ? collect(Missings.replace(c, 0)) : c, eachcol(fulltable))
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


function rm_strat!(df::DataFrame; col::Union{Int, Symbol}=1)
    filter!(x->!ismatch(r"\|", x[1]), df)
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