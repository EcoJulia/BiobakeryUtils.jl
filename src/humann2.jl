"""
Assumes input file is uniref90 (genefamilies)
"""
function humann2_regroup(df::DataFrame, kind::String="ec")
    in_path = tempname()
    out_path = tempname()
    CSV.write(df, in_path)
    run(```
        humann2_regroup_table -i $in_path -g uniref90_$kind -o $out_path
        ```)

    new_df = CSV.File(out_path) |> DataFrame
    return new_df[1]
end


function humann2_rename(df::DataFrame, kind::String="ec")
    in_path = tempname()
    out_path = tempname()
    CSV.write(df[[1]], in_path)
    run(```
        humann2_rename_table -i $in_path -n $kind -o $out_path
        ```)

    new_df = CSV.File(out_path) |> DataFrame
    return new_df[1]
end

function humann2_barplot(df::DataFrame, metadata::AbstractArray{<:AbstractString,1}, outpath::String)
    length(metadata) == size(df, 2) - 1 || @error "Must have metadata for each column"
    nostrat = view(df, .!occursin.("|", df[1]), :)

    metadf = DataFrame(metadata=["metadatum"])
    metadf = hcat(metadf, DataFrame([names(df[2:end])[i]=>metadata[i] for i in eachindex(metadata)]...))
    for p in nostrat[1]
        current = filter(x-> startswith(x[1], p), df)
        pwy = match(r"^([\w-]+)\:", p).captures[1]
        @debug "Size of $p dataframe" size(current)
        if size(current, 1) < 3
            @info "Only 1 classified species for $pwy, skipping"
            continue
        end
        @info "plotting $pwy"

        fl_path = tempname()
        outfl = open(fl_path, "w")
        CSV.write(metadf,  outfl)
        CSV.write(current, outfl, header=false)
        close(outfl)

        out = joinpath(outpath, "$pwy.png")
        @debug "humann2_barplot --i $fl_path -o $out --focal-feature $pwy --focal-metadatum metadatum --last-metadatum metadatum --sort sum metadata"
        run(```
            humann2_barplot --i $fl_path -o "$out" --focal-feature "$pwy" --focal-metadatum metadatum --last-metadatum metadatum --sort sum metadata
            ```)
    end
end
