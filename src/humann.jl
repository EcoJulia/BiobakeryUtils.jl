"""
    humann(inputfile, output[, flags]; kwargs...)

Run `humann` command line tool on `inputfile`,
putting outputs in `output`.
Requires `humann` to be installed and accessible in the `PATH`
(see [Getting Started](@ref)).

`humann` flag options (those that don't have a parameter) can be passed in an array,
and other options can be passed with keyword arguments.
For example, if on the command line you would run:

```sh
\$ humann -i \$INPUTFILE -o \$OUTPUT --bypass-tranlated-search --input-format fastq.gz --output-format biom
```

using this function, you would write:

```julia
humann(INTPUTFILE, OUTPUT, ["bypass_translated_search"]; input_formal="fastq.gz", output_format="biom")
```
"""
function humann(inputfile, output; kwargs...)
    check_for_install("humann")
    c = ["humann", "-i", inputfile, "-o", output]
    
    if !haskey(kwargs, :metaphlan_options) && haskey(ENV, "METAPHLAN_BOWTIE2_DB")
        append!(c, ["--metaphlan-options", "'--bowtie2db $(ENV["METAPHLAN_BOWTIE2_DB"])'"])
    end

    add_cli_kwargs!(c, kwargs)
    
    @info "Running command: $(Cmd(c))"
    return run(Cmd(c))
end

function _gf_parse(gf)
    if contains(gf, '|') # indicates a taxon-stratified entry
        (gf, tax) = split(gf, '|')
        if tax == "unclassified"
            tax = Taxon("unclassified")
        else
            tax = String(tax)
            tm = contains(tax, "s__") ? match(r"(s__)(\w+)", tax) :
                 contains(tax, "g__") ? match(r"(g__)(\w+)", tax) :
                                        match(r"^(\W*)(\w+)$", tax)
            isnothing(tm) && error("Incorrectly formatted taxon stratification: $tax")
            cld = isnothing(tm.captures[1]) || tm.captures[1] == "s__" ? :species : :genus
            tax = Taxon(string(tm.captures[2]), cld)
        end
        return GeneFunction(gf, tax)
    else
        return GeneFunction(gf)
    end
end
"""
    humann_profile(path::AbstractString; sample=basename(first(splitext(path))), stratified=false)

Load a single functional profile generated by `HUMAnN`.
By default, skips rows that have species-stratified content,
use `stratified=true` to keep them.
"""
function humann_profile(path::AbstractString; sample=basename(first(splitext(path))), stratified=false)
    gfs = GeneFunction[]
    abundances = Float64[]
    
    for (i, (gf, abundance)) in enumerate(CSV.File(path, skipto=2, header=["function", "abundance"]))   
        (!stratified && occursin('|', gf)) && continue
        push!(gfs, _gf_parse(gf))
        push!(abundances, abundance)
    end
    mat = sparse(reshape(abundances, length(abundances), 1))
    sample = sample isa Microbiome.AbstractSample ? sample : MicrobiomeSample(sample)

    return CommunityProfile(mat, gfs, [sample])
end

"""

"""
function humann_profiles(path::AbstractString; samples=nothing, stratified=false, skipto=2)
    tbl = CSV.File(path; skipto)
    gfs = GeneFunction[]
    if !isnothing(samples) 
        length(samples) == length(keys(first(tbl))) - 1 || throw(ArgumentError("Passed $(length(samples)) samples, but table has $(length(keys(first(tbl))) - 1)"))
    else
        samples = keys(first(tbl))[2:end]
    end

    stratified || (tbl = filter(row-> !occursin('|', row[1]), tbl))
    mat = spzeros(length(tbl), length(samples))

    for (i, (row)) in enumerate(tbl)
        push!(gfs, _gf_parse(row[1]))
        for j in 1:length(samples)
            mat[i, j] = ismissing(row[j+1]) ? 0 : row[j+1]
        end
    end
    samples = eltype(samples) == MicrobiomeSample ? samples : MicrobiomeSample.(string.(samples))
    return CommunityProfile(mat, gfs, samples)
end

"""
    function humann_regroup(comm::CommunityProfile; inkind="uniref90", outkind::String="ec")

Wrapper for `humann_regroup_table` script
to convert table from one kind of functional mapping to another.

Requires installation of [`humann`](https://github.com/biobakery/humann) available in `ENV["PATH"]`.
See "[Using Conda](@ref using-conda)" for more information.
"""
function humann_regroup(comm::CommunityProfile; inkind::String="uniref90", outkind::String="ec")
    check_for_install("humann_regroup_table")
    in_path = tempname()
    out_path = tempname()

    ss = samples(comm)
    CSV.write(in_path, comm; delim='\t')
    run(```
        humann_regroup_table -i $in_path -g $(inkind)_$outkind -o $out_path
        ```)

    return humann_profiles(out_path; samples=ss)
end

"""
    humann_rename(comm::AbstractDataFrame; kind::String="ec")

Wrapper for `humann_rename_table` script,
returning a CommunityProfile with re-named features.

Requires installation of [`humann`](https://github.com/biobakery/humann) available in `ENV["PATH"]`.
See "[Using Conda](@ref using-conda)" for more information.
"""
function humann_rename(comm::CommunityProfile; kind::String="ec")
    check_for_install("humann_rename_table")
    in_path = tempname()
    out_path = tempname()
    ss = samples(comm)
    
    CSV.write(in_path, comm; delim='\t')
    run(```
        humann_rename_table -i $in_path -n $kind -o $out_path
        ```)
    
    return humann_profiles(out_path; samples=ss)
end

"""
    humann_renorm(comm::AbstractDataFrame; units::String="cpm")

Wrapper for `humann_renorm_table` script,
to renormalize from RPKM (reads per kilobase per million)
to "cpm" (counts per million) or "relab" (relative abundance).

Requires installation of [`humann`](https://github.com/biobakery/humann) available in `ENV["PATH"]`.
See "[Using Conda](@ref using-conda)" for more information.
"""
function humann_renorm(comm::CommunityProfile; units="cpm")
    check_for_install("humann_renorm_table")
    in_path = tempname()
    out_path = tempname()
    ss = samples(comm)
    
    CSV.write(in_path, comm; delim='\t')
    run(```
        humann_renorm_table -i $in_path --units $units -o $out_path
        ```)
    
    return humann_profiles(out_path; samples=ss)
end

"""
    humann_renorm(comm::AbstractDataFrame; units::String="cpm")

Wrapper for `humann_renorm_table` script,
to renormalize from RPKM (reads per kilobase per million)
to "cpm" (counts per million) or "relab" (relative abundance).

Requires installation of [`humann`](https://github.com/biobakery/humann) available in `ENV["PATH"]`.
See "[Using Conda](@ref using-conda)" for more information.
"""
function humann_join(in_path, out_path; file_name=nothing, search_subdirectories=false, verbose=false)
    check_for_install("humann_join_tables")
    cmd = ["humann_join_tables", "-i", in_path, "-o", out_path]
    !isnothing(file_name) && append!(cmd, ["--file_name", file_name])
    search_subdirectories && push!(cmd, "--search-subdirectories")
    verbose && push!(cmd, " --verbose")

    run(Cmd(cmd))
end

"""
    read_pcl(infile; last_metadata=2)

Reads a [PCL file](https://software.broadinstitute.org/cancer/software/gsea/wiki/index.php/Data_formats#PCL:_Stanford_cDNA_file_format_.28.2A.pcl.29)
and generates a `CommunityProfile` with metadata attached to the samples.

`last_metadata` may be a row number or a string representing the final metadatum.
"""
function read_pcl(infile; last_metadata=2)
    if last_metadata isa Int
        lr = last_metadata
    else
        lr = 1
        for line in eachline(infile)
            startswith(line, last_metadata) && break
            lr+=1
        end
    end

    md_rows = CSV.File(infile, limit=lr-1, threaded=false)
    cols = keys(first(md_rows))[2:end]
    gfs = humann_profiles(infile; stratified=true, skipto=lr+1)
    for row in md_rows
        md = Symbol(row[1])
        for col in cols
            set!(gfs, string(col), md, row[col])
        end
    end
    return gfs                
end

"""
    write_pcl(infile; usemetadata=:all)

Writes a [PCL file](https://software.broadinstitute.org/cancer/software/gsea/wiki/index.php/Data_formats#PCL:_Stanford_cDNA_file_format_.28.2A.pcl.29)
from a `CommunityProfile` with metadata attached to the samples.

`usemetadata` may be `:all` 
or a vector of symbols.
"""
function write_pcl(path, comm::CommunityProfile; usemetadata=:all)
    coltab = Tables.columntable(metadata(comm))
    if usemetadata == :all
        usemetadata = collect(keys(coltab))
        popfirst!(usemetadata)
    end
    cols = Symbol.(coltab.sample)
    pushfirst!(cols, :thing)
    tbl =  (; zip(cols, [[usemetadata]..., [[coltab[md][i] for md in usemetadata] for i in 1:length(cols)-1]...])...)
    CSV.write(path, tbl; delim='\t')

    CSV.write(path, comm; append=true, delim='\t')
end

"""
    humann_barplot(comm::CommunityProfile, outpath; kwargs...)

Wrapper for `humann_barplot` script,
to generate plots from functional data.
pass keyword arguments for script options.
Flag arguments should be set to `true`. eg

```julia-repl
julia> humann_barplot(comm, "plot.png"; focal_metadata="STSite", focal_feature="COA-PWY",
                      sort="braycurtis",
                      scaling="logstack",
                      as_genera=true,
                      remove_zeros=true)
```

Requires installation of [`humann`](https://github.com/biobakery/humann) available in `ENV["PATH"]`.
See "[Using Conda](@ref using-conda)" for more information.
"""
function humann_barplot(comm::CommunityProfile, outpath; kwargs...)
    check_for_install("humann_barplot")
    tmp = tempname()
    write_pcl(tmp, comm)

    cmd = ["humann_barplot", "--i", tmp, "-o", outpath,
            "--last-metadata", string(last(keys(first(metadata(comm)))))]
    
    add_cli_kwargs!(cmd, kwargs)
    run(Cmd(cmd))
end
