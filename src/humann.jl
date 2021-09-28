"""
    function humann_regroup(df::AbstractDataFrame; inkind="uniref90", outkind::String="ec")

Wrapper for `humann_regroup` script,
replaces first column of a DataFrame with results from
regrouping `inkind` to `outkind`.

Requires installation of [`humann`](https://github.com/biobakery/humann) available in `ENV["PATH"]`.
See "[Using Conda](@ref)" for more information.
"""
function humann_regroup(df::AbstractDataFrame; inkind::String="uniref90", outkind::String="ec")
    in_path = tempname()
    out_path = tempname()
    CSV.write(in_path, df)
    run(```
        humann_regroup_table -i $in_path -g $(inkind)_$outkind -o $out_path
        ```)

    new_df = CSV.File(out_path) |> DataFrame
    return new_df[!,1]
end

"""
    humann_rename(df::AbstractDataFrame; kind::String="ec")

Wrapper for `humann_rename` script,
replaces first column of a DataFrame with results from
renaming `inkind` to `outkind`.

Requires installation of [`humann`](https://github.com/biobakery/humann) available in `ENV["PATH"]`.
See "[Using Conda](@ref)" for more information.
"""
function humann_rename(df::AbstractDataFrame; kind::String="ec")
    in_path = tempname()
    out_path = tempname()
    CSV.write(in_path, df[!, [1]], delim='\t')
    run(```
        humann_rename_table -i $in_path -n $kind -o $out_path
        ```)
    new_df = CSV.File(out_path, delim='\t') |> DataFrame
    return new_df[!,1]
end


function humann_barplots(df::AbstractDataFrame, metadata::AbstractArray{<:AbstractString,1}, outpath::String)
    length(metadata) == size(df, 2) - 1 || @error "Must have metadata for each column"
    nostrat = df[map(x-> !occursin(r"\|", x), df[!,1]), 1]
    for p in nostrat
        pwy = match(r"^[\w.]+", p).match
        @debug pwy
        filt = [occursin(Regex("^$pwy\\b"), x) for x in df[!,1]]
        current = df[filt, :]
        @debug "Size of $p dataframe" size(current)
        if size(current, 1) < 3
            @info "Only 1 classified species for $p, skipping"
            continue
        end
        @info "plotting $p"

        BiobakeryUtils.humann_barplot(current, metadata, outpath)
    end
end

function humann_barplot(df::AbstractDataFrame, metadata::AbstractArray{<:AbstractString,1}, outpath::AbstractString)
    sum(x-> !occursin(r"\|", x), df[!,1]) == 1 || @error "Multipl unstratified rows in dataframe"
    matches = map(x-> match(r"^([^:|]+):?([^|]+)?", x),  df[!,1])
    all(x-> !isa(x, Nothing), matches) || @error "something is wrong!"
    @debug "Getting unique"
    ecs = unique([String(x.captures[1]) for x in matches])
    length(ecs) == 1 || @error "Multiple ecs found in df"
    ec = ecs[1]

    metadf = DataFrame(metadata=["metadatum"])
    metadf = hcat(metadf, DataFrame([names(df)[2:end][i]=>metadata[i] for i in eachindex(metadata)]...))
    @debug "opening file"
    fl_path = tempname()
    outfl = open(fl_path, "w")
    CSV.write(outfl, metadf, delim='\t')
    CSV.write(outfl, df, append=true, delim='\t')
    close(outfl)
    @debug "file closed"

    out = joinpath(outpath, "$ec.png")
    @debug "humann_barplot --i $fl_path -o $out --focal-feature $ec --focal-metadatum metadatum --last-metadatum metadatum --sort sum metadata"
    run(```
        humann_barplot --i $fl_path -o "$out" --focal-feature "$ec" --focal-metadatum metadatum --last-metadatum metadatum --sort sum metadata
        ```)

end