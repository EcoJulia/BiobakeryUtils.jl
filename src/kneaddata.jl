"""
    kneaddata(inputfile, outputfile; kwargs...)

Run `kneaddata` command line tool on `inputfile`,
creating `outputfile`.
Requires `kneaddata` to be installed and accessible in the `PATH`
(see [Getting Started](@ref)).

`kneaddata` options can be passed via keyword arguments.
For example, if on the command line you would run:

```sh
\$ kneaddata -i some.fastq.gz -o test --n 8 --bypass-trim
```

using this function, you would write:

```julia
kneaddata("some.fastq.gz", "test"; n = 8, bypass_trim=true)
```

To pass multiple databases,
pass an array of paths to the `reference_db` argument

Conda installations of `trimmomatic` (a dependency of `kneaddata`)
don't work properly out of the box.
If you have installed `kneaddata` using commandline conda
(instead of `Conda.jl`),
use `trimmomatic = /path/to/trimmomatic`,
where `/path/to/trimmomatic` is something like
`/home/username/miniconda3/envs/biobakery3/share/trimmomatic`.
If you used `BiobakeryUtils.install_deps()`,
you don't need to worry about this.
"""
function kneaddata(inputs, output; kwargs...)
    check_for_install("kneaddata")
    c = ["kneaddata"]
    if inputs isa AbstractString
        append!(c, ["-i", inputs])
    else
        length(inputs) > 2 && error("for now, only 2 input files possible")
        append!(c, ["-i", inputs[1], "-i", inputs[2]])
    end
    
    append!(c, ["-o", output])

    if !haskey(kwargs, :trimmomatic)
        env = get(kwargs, :condaenv, :BiobakeryUtils)
        trimpath = normpath(joinpath(Conda.bin_dir(env), "..", "share"), "trimmomatic")

        append!(c, ["--trimmomatic", trimpath])
    end

    if haskey(kwargs, :reference_db)
        if kwargs[:reference_db] isa String
            append!(c, ["-db", kwargs[:reference_db]])
        else
            for db in kwargs[:reference_db]
                append!(c, ["-db", db])
            end
        end
    end

    add_cli_kwargs!(c, kwargs; optunderscores=false, skip=[:reference_db])
    
    @info "Running command: $(Cmd(c))"
    return CondaPkg.withenv() do run(Cmd(c)) end
end

"""
    kneaddata_database(db, kind, path)

See `kneaddata_database --help`

```julia
kneaddata_database("human_genome", "bowtie2", "/some/database/dir/")
```
"""
function kneaddata_database(db, kind, path)
    check_for_install("kneaddata_database")
    c = ["kneaddata_database", "--download", db, kind, path]
    
    @info "Running command: $(Cmd(c))"
    return CondaPkg.withenv() do run(Cmd(c)) end
end

"""
    kneaddata_read_count_table(input, output)

See `kneaddata_read_count_table --help`

```julia
kneaddata_read_count_table("human_genome", "bowtie2", "/some/database/dir/")
```
"""
function kneaddata_read_count_table(input, output)
    check_for_install("kneaddata_read_count_table")
    c = ["kneaddata_read_count_table", "--input", input, "--output", output]
    
    @info "Running command: $(Cmd(c))"
    return CondaPkg.withenv() do run(Cmd(c)) end
end

