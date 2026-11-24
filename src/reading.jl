abstract type ProfileFormat end
struct HUMAnNFormat <: ProfileFormat
    stratified::Bool
end
struct MetaPhlAnFormat <: ProfileFormat
    rank::Symbol
end

_feature_type(::HUMAnNFormat) = GeneFunction
_feature_type(::MetaPhlAnFormat) = Taxon

function _source_name(path)
    filename = basename(path)
    for suffix in (".xz", ".gz", ".tsv", ".txt", ".csv")
        endswith(filename, suffix) && (filename = chop(filename; tail = length(suffix)))
    end
    return filename
end

_profile_sample(sample::AbstractString) = MicrobiomeSample(sample)
_profile_sample(sample::AbstractSample) = sample
_table_sample(sample::AbstractSample) = sample
_table_sample(sample) = MicrobiomeSample(string(sample))

_decompress(io, ::Val{:plain}) = io
_decompress(io, ::Val{:xz}) = XzDecompressorStream(io)
_decompress(io, ::Val{:gz}) = GzipDecompressorStream(io)

function _open_profile(f, path)
    codec = endswith(path, ".xz") ? :xz : endswith(path, ".gz") ? :gz : :plain
    return open(path) do raw
        io = _decompress(raw, Val(codec))
        try
            f(io)
        finally
            close(io)
        end
    end
end

function _csv_profile(f, path)
    if endswith(path, ".xz") || endswith(path, ".gz")
        return _open_profile(f, path)
    end
    return f(path)
end

function _terminal_taxon(key)
    separator = findlast(==('|'), key)
    return taxon(isnothing(separator) ? key : SubString(key, nextind(key, separator)))
end

function _metaphlan_layout(data)
    valuecol = 2
    for (row, line) in enumerate(eachline(IOBuffer(data)))
        isempty(strip(line)) && continue
        fields = split(line, '\t')
        if startswith(line, "#clade_name") || first(fields) == "clade_name"
            column = findfirst(==("relative_abundance"), fields)
            if startswith(line, '#')
                isnothing(column) && throw(ArgumentError("MetaPhlAn header has no relative_abundance column."))
            end
            isnothing(column) || (valuecol = column)
            continue
        end
        startswith(line, '#') && continue
        first(fields) in ("ID", "taxon") && continue
        length(fields) >= valuecol || throw(ArgumentError("MetaPhlAn table has no abundance column."))
        return (skipto = row, valuecol = valuecol)
    end
    return (skipto = 0, valuecol = valuecol)
end

"""
    read_metaphlan(path::AbstractString)
    read_metaphlan(io::IO)

Read a single-sample MetaPhlAn table into a Tables-compatible column table with
`feature` (full clade strings) and `abundance` columns. Named headers select
`relative_abundance`, including tables with extra coverage/read-count columns.
Legacy two-column tables are supported. Paths may be plain, gzip, or XZ; supplied
IO must already be decompressed and remains open. No Microbiome features are built.
"""
read_metaphlan(path::AbstractString) = _open_profile(read_metaphlan, path)

function read_metaphlan(io::IO)
    data = read(io)
    layout = _metaphlan_layout(data)
    iszero(layout.skipto) && return (feature = String[], abundance = Float64[])
    table = CSV.File(
        data; header = false, skipto = layout.skipto, comment = "#",
        select = [1, layout.valuecol], types = Dict(1 => String), delim = '\t'
    )
    return (feature = collect(Tables.getcolumn(table, 1)), abundance = collect(Tables.getcolumn(table, 2)))
end

"""
    read_humann(path::AbstractString)
    read_humann(io::IO)

Read a single-sample HUMAnN table into a Tables-compatible column table with raw
`feature` strings and Float64 `abundance` values. Stratified identifiers are retained
unchanged. Paths may be plain, gzip, or XZ; supplied IO must already be decompressed
and remains open. No Microbiome features are built.
"""
read_humann(path::AbstractString) = _csv_profile(_read_humann_csv, path)
read_humann(io::IO) = _read_humann_csv(io)

function _read_humann_csv(source)
    table = CSV.File(
        source; skipto = 2, header = ["feature", "abundance"],
        types = Dict(2 => Float64), strict = true
    )
    isempty(table) && return (feature = String[], abundance = Float64[])
    return (feature = collect(table.feature), abundance = collect(table.abundance))
end

_read_profile(path, ::HUMAnNFormat) = read_humann(path)
_read_profile(path, ::MetaPhlAnFormat) = read_metaphlan(path)
_parse_feature(::HUMAnNFormat, key) = _gf_parse(key)
_parse_feature(::MetaPhlAnFormat, key) = _terminal_taxon(key)
_include_raw(kind::HUMAnNFormat, key) = kind.stratified || !occursin('|', key)
_include_raw(::MetaPhlAnFormat, key) = true
_keep_profile_feature(::HUMAnNFormat, feature) = true
_keep_profile_feature(kind::MetaPhlAnFormat, feature) = kind.rank == :all || ismissing(taxrank(feature)) || taxrank(feature) == kind.rank

struct _ProfileBuilder{F}
    features::Vector{F}
    keyrows::Dict{String, Int}
    featurerows::Dict{F, Int}
    rows::Vector{Int}
    cols::Vector{Int}
    values::Vector{Float64}
end

_ProfileBuilder(::Type{F}) where {F} = _ProfileBuilder(F[], Dict{String, Int}(), Dict{F, Int}(), Int[], Int[], Float64[])

function _append_profile_table!(builder, table, format, column)
    seen = Set{Int}()
    for (key, abundance) in zip(table.feature, table.abundance)
        _include_raw(format, key) || continue
        row = get(builder.keyrows, key, -1)
        if row == -1
            stablekey = String(key)
            feature = _parse_feature(format, stablekey)
            row = if _keep_profile_feature(format, feature)
                get!(builder.featurerows, feature) do
                    push!(builder.features, feature)
                    length(builder.features)
                end
            else
                0
            end
            builder.keyrows[stablekey] = row
        end
        iszero(row) && continue
        row in seen && throw(ArgumentError("Duplicate feature in sample column $column: $key"))
        push!(seen, row)
        value = Float64(abundance)
        if !iszero(value)
            push!(builder.rows, row)
            push!(builder.cols, column)
            push!(builder.values, value)
        end
    end
    return builder
end

function _load_profiles(paths, format; samples = nothing)
    isempty(paths) && throw(ArgumentError("At least one source path is required."))
    paths = collect(paths)
    names = isnothing(samples) ? _source_name.(paths) : collect(samples)
    length(names) == length(paths) || throw(ArgumentError("Number of paths and samples does not match."))
    sample_objects = _profile_sample.(names)
    allunique(name.(sample_objects)) || throw(ArgumentError("Duplicate sample names detected."))
    builder = _ProfileBuilder(_feature_type(format))
    for (column, path) in enumerate(paths)
        table = _read_profile(path, format)
        _append_profile_table!(builder, table, format, column)
    end
    matrix = sparse(builder.rows, builder.cols, builder.values, length(builder.features), length(sample_objects))
    return CommunityProfile(matrix, builder.features, sample_objects)
end

function _table_abundances(table, kept, columns)
    rows, cols, values = Int[], Int[], Float64[]
    for (column, sourcecol) in enumerate(columns)
        _append_table_column!(rows, cols, values, Tables.getcolumn(table, sourcecol), kept, column)
    end
    return sparse(rows, cols, values, length(kept), length(columns))
end

function _append_table_column!(rows, cols, values, data, kept, column)
    for (row, sourceidx) in enumerate(kept)
        value = Float64(coalesce(data[sourceidx], 0))
        if !iszero(value)
            push!(rows, row)
            push!(cols, column)
            push!(values, value)
        end
    end
    return nothing
end
