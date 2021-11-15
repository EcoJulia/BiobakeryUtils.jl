```@meta
CurrentModule = BiobakeryUtils
DocTestSetup  = quote
    using BiobakeryUtils
    using BiobakeryUtils.Conda
    BiobakeryUtils.install_deps()
    ENV["PATH"] = ENV["PATH"] * Conda.bind_dir(:BiobakeryUtils)
end
```
# [KneadData Tutorial with BiobakeryUtils.jl](@id kneaddata-tutorial)


- 🗒️ This tutorial is meant to be run in parallel with / mirror the [official KneadData](https://github.com/biobakery/biobakery/wiki/kneaddata)
- ❓️ If you have questions about MetaPhlAn itself, please direct them to the [bioBakery help forum](https://forum.biobakery.org/c/Microbial-community-profiling/MetaPhlAn)
- 🤔 If you have questions about using the MetaPhlAn tools in julia, [please open an issue](https://github.com/EcoJulia/BiobakeryUtils.jl/issues/new/choose),
  or start a discussion over on [`Microbiome.jl`](https://github.com/EcoJulia/Microbiome.jl/discussions/new)!
- 📔 For a function / type reference, [jump to the bottom](#Functions-and-Types)

## Installation and setup

If you haven't already,
check out the ["Getting Started"](@ref getting-started) page to install julia,
create an environment,xd and install BiobakeryUtils.jl,
and hook up or install the MetaPhlAn v3 command line tools.

This tutorial assumes:

1. You are running julia v1.6 or greater
2. You have activated a julia Project that has `BiobakeryUtils.jl` installed
3. The `kneaddata` python package is installed, and accessible from your `PATH`.

If any of those things aren't true, or you don't know if they're true,
go back to ["Getting Started"](@ref getting-started) to see if you skipped a step.
If you're still confused, please ask (see 3rd bullet point at the top)!

### Contamination databases

By default, kneaddata will only trim reads
based on quality scores.
If you would also like to remove contaminating sequences
(eg from human or mouse DNA reads),
you'll need to download them.

```@docs
BiobakeryUtils.kneaddata_database
```

To see what databases are available,
you need to use the command line,
`kneaddata_database --available`.

### Demo files

The demo files for the kneaddata tutorial can be found
in this package's `test` folder,
which you can find with

```jldoctest
julia> demo = abspath(joinpath(dirname(Base.find_package("BiobakeryUtils")), "..", "test", "files", "kneaddata"));

julia> readdir(demo)
10-element Vector{String}:
 "SE_extra.fastq"
 "demo_db.1.bt2"
 "demo_db.2.bt2"
 "demo_db.3.bt2"
 "demo_db.4.bt2"
 "demo_db.rev.1.bt2"
 "demo_db.rev.2.bt2"
 "seq1.fastq"
 "seq2.fastq"
 "singleEnd.fastq"
```

## Running on a single-end sequencing data

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/kneaddata#single-end-reads)

You can use the `kneaddata` commandline tool
using the [`kneaddata()`](@ref) function from BiobakeryUtils.jl

```julia
julia> kneaddata(joinpath(demo, "singleEnd.fastq"), "kneaddataOutputSingleEnd"; reference_db=joinpath(demo, "demo_db"))
┌ Info: Running command: kneaddata -i /home/kevin/.julia/dev/BiobakeryUtils/test/files/kneaddata/singleEnd.fastq -o
│ kneaddataOutputSingleEnd --trimmomatic /home/kevin/.julia/conda/3/envs/BiobakeryUtils/share/trimmomatic -db
└ /home/kevin/.julia/dev/BiobakeryUtils/test/files/kneaddata/demo_db
Reformatting file sequence identifiers ...

Initial number of reads ( /tmp/jl_JXPuAs/kneaddataOutputSingleEnd/reformatted_identifiersjlcp_ry6_singleEnd ): 16902.0
# ... etc
```


## Running on paired-end sequencing data

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/kneaddata#paired-end-reads)

To run on paired end data,
simply pass an array of file paths to the `input` argument.

```julia
julia> kneaddata([joinpath(demo, "seq1.fastq"), joinpath(demo, "seq2.fastq")],
                   "kneaddataOutputPairedEnd"; reference_db=joinpath(demo, "demo_db"))
┌ Info: Running command: kneaddata -i /home/kevin/.julia/dev/BiobakeryUtils/test/files/kneaddata/seq1.fastq -i
│ /home/kevin/.julia/dev/BiobakeryUtils/test/files/kneaddata/seq2.fastq -o kneaddataOutputPairedEnd --trimmomatic
│ /home/kevin/.julia/conda/3/envs/BiobakeryUtils/share/trimmomatic -db
└ /home/kevin/.julia/dev/BiobakeryUtils/test/files/kneaddata/demo_db
Initial number of reads ( /home/kevin/.julia/dev/BiobakeryUtils/test/files/kneaddata/seq1.fastq ): 42473.0
Initial number of reads ( /home/kevin/.julia/dev/BiobakeryUtils/test/files/kneaddata/seq2.fastq ): 42473.0
Running Trimmomatic ...
Total reads after trimming ( /tmp/jl_JXPuAs/kneaddataOutputPairedEnd/seq1_kneaddata.trimmed.1.fastq ): 35341.0
Total reads after trimming ( /tmp/jl_JXPuAs/kneaddataOutputPairedEnd/seq1_kneaddata.trimmed.2.fastq ): 35341.0
Total reads after trimming ( /tmp/jl_JXPuAs/kneaddataOutputPairedEnd/seq1_kneaddata.trimmed.single.1.fastq ): 5385.0
Total reads after trimming ( /tmp/jl_JXPuAs/kneaddataOutputPairedEnd/seq1_kneaddata.trimmed.single.2.fastq ): 847.0
```




## API Reference

```@docs
kneaddata
```