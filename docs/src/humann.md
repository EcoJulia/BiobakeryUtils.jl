# HUMAnN Tutorial with BiobakeryUtils.jl

- 🗒️ This tutorial is meant to be run in parallel with / mirror the [official HUMAnN v3 tutorial](https://github.com/biobakery/biobakery/wiki/humann3)
- ❓️ If you have questions about MetaPhlAn itself, please direct them to the [bioBakery help forum](https://forum.biobakery.org/c/Microbial-community-profiling/HUMAnN)
- 🤔 If you have questions about using the MetaPhlAn tools in julia, [please open an issue](https://github.com/BioJulia/BiobakeryUtils.jl/issues/new/choose),
  or start a discussion over on [`Microbiome.jl`](https://github.com/BioJulia/Microbiome.jl/discussions/new)!
- 📔 For a function / type reference, [jump to the bottom](#Functions-and-Types)

## Installation and setup

If you haven't already,
check out the ["Getting Started"](gettingstarted) page to install julia,
create an environment and install BiobakeryUtils.jl,
and hook up or install the MetaPhlAn v3 command line tools.

This tutorial assumes:

1. You are running julia v1.6 or greater
2. You have activated a julia Project that has `BiobakeryUtils.jl` installed
3. The `humann` python package is installed, and accessible from your `PATH`.

If any of those things aren't true, or you don't know if they're true,
go back to ["Getting Started"](gettingstarted) to see if you skipped a step.
If you're still confused, please ask (see 3rd bullet point at the top)!

### HUMAnN Databases

HUMAnN requires a number of specialized databases to work correctly.
When you first install it, it comes with some demo databases that are much smaller,
but can be used to complete this tutorial.
However, for actually running real data, you'll want to take the time
to download them - they're BIG!
[See here](https://github.com/biobakery/humann#5-download-the-databases) for more information.

For now, the easiest way to do this for now is via the shell,
which you can access from the julia REPL by typing `;`:

```julia-repl
shell> humann_databases --help
usage: humann_databases [-h] [--available]
                        [--download <database> <build> <install_location>]
                        [--update-config {yes,no}]
                        [--database-location DATABASE_LOCATION]

HUMAnN Databases

optional arguments:
  -h, --help            show this help message and exit
  --available           print the available databases
  --download <database> <build> <install_location>
                        download the selected database to the install location
  --update-config {yes,no}
                        update the config file to set the new database as the default [DEFAULT: yes]
  --database-location DATABASE_LOCATION
                        location (local or remote) to pull the database

shell> humann_databases --available
HUMANnN2 Databases ( database : build = location )
chocophlan : full = http://huttenhower.sph.harvard.edu/humann_data/chocophlan/full_chocophlan.v296_201901b.tar.gz
chocophlan : DEMO = http://huttenhower.sph.harvard.edu/humann_data/chocophlan/DEMO_chocophlan.v296_201901b.tar.gz
uniref : uniref50_diamond = http://huttenhower.sph.harvard.edu/humann_data/uniprot/uniref_annotated/uniref50_annotated_v201901b_ful
l.tar.gz
uniref : uniref90_diamond = http://huttenhower.sph.harvard.edu/humann_data/uniprot/uniref_annotated/uniref90_annotated_v201901b_ful
l.tar.gz
uniref : uniref50_ec_filtered_diamond = http://huttenhower.sph.harvard.edu/humann_data/uniprot/uniref_ec_filtered/uniref50_ec_filte
red_201901b_subset.tar.gz
uniref : uniref90_ec_filtered_diamond = http://huttenhower.sph.harvard.edu/humann_data/uniprot/uniref_ec_filtered/uniref90_ec_filte
red_201901b_subset.tar.gz
uniref : DEMO_diamond = http://huttenhower.sph.harvard.edu/humann_data/uniprot/uniref_annotated/uniref90_DEMO_diamond_v201901b.tar.
gz
utility_mapping : full = http://huttenhower.sph.harvard.edu/humann_data/full_mapping_v201901b.tar.gz
```

For example, if you'd like to install these databases to `/BigDrive/humann/`,
you could run

```julia-repl
shell> humann_databases --download cholophlan full /BigDrive/humann/chocophlan
# ... lots of output

shell> humann_databases --download uniref uniref90_diamond /BigDrive/humann/uniref
# ... lots of output

shell> humann_databases --download utility_mapping full /BigDrive/humann/utility_mapping
# ... lots of output
```

At some point, I'll write some functions to automate this, but for now,
doing this will update a configuration file, so you shouldn't have to worry about it again.

## Running HUMAnN

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/humann3#2-metagenome-functional-profiling)

Some example files you can use to run this tutorial are available from the MetaPhlAn repo,
and can be downloaded using the `Downloads` standard library in julia:

```julia-repl
julia> using Downloads: download

julia> base_url = "https://github.com/biobakery/humann/raw/master/examples/";

julia> files = [
           "demo.fastq.gz",
           "demo.sam",
           "demo.m8"
       ];

julia> for file in files
           download(joinpath(base_url, file), file)
       end

julia> readdir()
5-element Vector{String}:
 "Manifest.toml"
 "Project.toml"
 "demo.fastq.gz"
 "demo.sam"
 "demo.m8"
```

For convenience, this package has the [`humann()`](@ref) function,
which can be used in your julia scripts to build and call the `humann` command line tool.

For example, rather than call

```sh
$ humann --input demo.fastq.gz --output demo_fastq
```

You can do

```julia-repl
julia> humann("demo.fastq.gz", "demo_fastq")
[ Info: Running command: humann -i demo.fastq.gz -o demo_fastq
Creating output directory: /home/kevin/my_project/demo_fastq
Output files will be written to: /home/kevin/my_project/demo_fastq
Decompressing gzipped file ...
```

First, `humann` will run `metaphlan` to generate taxonomic profiles,
then will use that taxonomic profile to run a custom gene search.
## Default outputs

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/humann3#23-humann-default-outputs)

To load a profile generated by `humann`,
use the `humann_profile` function:

```julia-repl
julia> gfs = humann_profile("demo_fastq/demo_genefamilies.tsv")
Microbiome.CommunityProfile{Float64, Microbiome.GeneFunction, Microbiome.MicrobiomeSample} with 589 things in 1 places

Thing names:
UNMAPPED, UniRef90_G1UL42, UniRef90_I9QXW8...UniRef90_A6LH06, UniRef90_D0TRR5

Place names:
demo_genefamilies
```

HUMAnN generates "stratified" gene function profiles - 
in other words, each gene function is also split into the species that contributed it.
By default, `human_profile` skips the stratified rows (they can get big!):

```julia-repl
julia> first(features(gfs), 5)
5-element Vector{GeneFunction}:
 GeneFunction("UNMAPPED", missing)
 GeneFunction("UniRef90_G1UL42", missing)
 GeneFunction("UniRef90_I9QXW8", missing)
 GeneFunction("UniRef90_A0A174QBF2", missing)
 GeneFunction("UniRef90_A0A078RDY6", missing)
```

The `missing` component of the `GeneFunction` means that these gene functions
are not associated with a particular taxon.

If you want to hang onto the taxon information,
use the keyword argument `stratified = true`:

```julia-repl
julia> first(features(gfs), 5)
5-element Vector{GeneFunction}:
 GeneFunction("UNMAPPED", missing)
 GeneFunction("UniRef90_G1UL42", missing)
 GeneFunction("UniRef90_I9QXW8", missing)
 GeneFunction("UniRef90_A0A174QBF2", missing)
 GeneFunction("UniRef90_A0A078RDY6", missing)

julia> gfs_strat = humann_profile("demo_fastq/demo_genefamilies.tsv", stratified=true)
CommunityProfile{Float64, GeneFunction, MicrobiomeSample} with 1416 features in 1 samples

Feature names:
UNMAPPED, UniRef90_G1UL42, UniRef90_G1UL42...UniRef90_D0TRR5, UniRef90_D0TRR5

Sample names:
demo_genefamilies



julia> first(features(gfs_strat), 5)
5-element Vector{GeneFunction}:
 GeneFunction("UNMAPPED", missing)
 GeneFunction("UniRef90_G1UL42", missing)
 GeneFunction("UniRef90_G1UL42", Taxon("Bacteroides_dorei", :species))
 GeneFunction("UniRef90_I9QXW8", missing)
 GeneFunction("UniRef90_I9QXW8", Taxon("Bacteroides_dorei", :species))
```

Here, we can see that the uniref90 "G1UL42" was contributed by _Bacteroides dorei_.

The object returned by `humann_profile` is a `CommunityProfile` type from [`Microbiome.jl`](https://github.com/BioJulia/Microbiome.jl),
and has a bunch of useful properties.

### Indexing

For example, you can index into a `CommunityProfile` just like you would a matrix.
In julia, you can pull out specific values using `[row, col]`.
So for example, to get the 3rd row, 2nd column, of matrix `mat`:

```julia-repl
julia> mat
4×3 Matrix{Int64}:
  1   2   3
  4   5   6
  7   8   9
 10  11  12

julia> mat[3,2]
8
```

You can also get "slices", eg to get rows 2-4, column 1:

```julia-repl
julia> mat[2:4, 1]
3-element Vector{Int64}:
  4
  7
 10
```

To get all of one dimension, you can just use a bare `:`

```julia-repl
julia> mat[:, 1:2]
4×2 Matrix{Int64}:
  1   2
  4   5
  7   8
 10  11
```

For `CommunityProfile`s,
you can index with numbers as above, but also with strings
representing names of features (rows) or samples (columns):

```julia-repl
julia> samplenames(gfs_strat)
1-element Vector{String}:
 "demo_genefamilies"

julia> featurenames(gfs_strat)
1416-element Vector{String}:
 "UNMAPPED"
 "UniRef90_G1UL42"
 "UniRef90_G1UL42"
 "UniRef90_I9QXW8"
 ⋮
 "UniRef90_A6LH06"
 "UniRef90_D0TRR5"
 "UniRef90_D0TRR5"
 "UniRef90_D0TRR5"

julia> slice = gfs_strat["UniRef90_D0TRR5", :]
CommunityProfile{Float64, GeneFunction, MicrobiomeSample} with 3 features in 1 samples

Feature names:
UniRef90_D0TRR5, UniRef90_D0TRR5, UniRef90_D0TRR5

Sample names:
demo_genefamilies



julia> features(slice)
3-element Vector{GeneFunction}:
 GeneFunction("UniRef90_D0TRR5", missing)
 GeneFunction("UniRef90_D0TRR5", Taxon("Bacteroides_vulgatus", :species))
 GeneFunction("UniRef90_D0TRR5", Taxon("Bacteroides_dorei", :species))
```

For gene functions, using a string to index will return
all rows, regardless of the taxon.
If you just want a single value, you can use a `GeneFunction` directly:

```julia-repl
julia> gfs_strat[GeneFunction("UniRef90_D0TRR5", "Bacteroides_dorei"), 1]
0.8271298594
```

You can even pass an array of strings as the row index
to get a slice with multiple gene functions:

```julia-repl
julia> features(gfs_strat[["UniRef90_D0TRR5", "UniRef90_A6L100"], :])
5-element Vector{GeneFunction}:
 GeneFunction("UniRef90_A6L100", missing)
 GeneFunction("UniRef90_A6L100", Taxon("Bacteroides_vulgatus", :species))
 GeneFunction("UniRef90_D0TRR5", missing)
 GeneFunction("UniRef90_D0TRR5", Taxon("Bacteroides_vulgatus", :species))
 GeneFunction("UniRef90_D0TRR5", Taxon("Bacteroides_dorei", :species))
```

## Manipulating tables

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/humann3#3-manipulating-humann-output-tables)

- Do all of this in CommProfile

### Normalize RPK to relative abundance

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/humann3#31-normalizing-rpks-to-relative-abundance)


### Regrouping genes to other functional categories

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/humann3#32-regrouping-genes-to-other-functional-categories)

- use `humann_regroup`

### Attaching names to features

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/humann3#33-attaching-names-to-features)

- use `humann_rename`

## HUMAnN for multiple samples

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/humann3#42-humann-for-multiple-samples)


## Plotting

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/humann3#5-plotting-stratified-functions)

- Kevin should do this
## Functions and types

```@autodocs
Modules = [BiobakeryUtils]
Pages = ["humann.jl"]
```
