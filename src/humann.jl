"""
Stratified import currently non-functional
"""
function humann_profile(path::AbstractString; sample=basename(first(splitext(path))), stratified=false)
    gfs = GeneFunction[]
    abundances = Float64[]
    
    for (i, (gf, abundance)) in enumerate(CSV.File(path, datarow=2, header=["function", "abundance"]))
        if occursin('|', gf) # indicates a taxon-stratified entry
            stratified || continue
            # (gf, tax) = split(gf, '|')
            # if tax == "unclassified"
            #     tax = Taxon("unclassified")
            # else
            #     tm = match(r"s__(\w+)", tax)
            #     cld = :species
            #     if isnothing(tm)
            #         tm = match(r"g__(\d+)", tax)
            #         cld = :genus
            #         isnothing(tm) && error("Incorrectly formatted taxon stratification: $tax")
            #     end
            #     tax = Taxon(string(tm.captures[1]), cld)
            # end
            # push!(gfs, GeneFunction(gf, tax))
        else
            push!(gfs, GeneFunction(gf))
        end
        push!(abundances, abundance)
    end
    mat = sparse(reshape(abundances, length(abundances), 1))
    sample = sample isa Microbiome.AbstractSample ? sample : MicrobiomeSample(sample)

    return CommunityProfile(mat, gfs, [sample])
end

"""
Stratified import currently non-functional
"""
function humann_profiles(path::AbstractString; samples=nothing, stratified=false)
    tbl = CSV.File(path)
    gfs = GeneFunction[]
    if !isnothing(samples) 
        length(samples) == length(keys(first(tbl))) - 1 || throw(ArgumentError("Passed $(length(samples)) samples, but table has $(length(keys(first(tbl))) - 1)"))
    else
        samples = keys(first(tbl))[2:end]
    end

    # Need to add code to deal with stratified input
    tbl = filter(row-> !occursin('|', row[1]), tbl)
    mat = spzeros(length(tbl), length(samples))

    for (i, (row)) in enumerate(tbl)
        push!(gfs, GeneFunction(row[1]))
        for j in 1:length(samples)
            mat[i, j] = row[j+1]
        end
    end
    samples = eltype(samples) == MicrobiomeSample ? samples : MicrobiomeSample.(string.(samples))
    return CommunityProfile(mat, gfs, samples)
end

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
