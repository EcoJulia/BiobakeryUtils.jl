# [HUMAnN Tutorial with BiobakeryUtils.jl](@id humann-tutorial)

- 🗒️ This tutorial is meant to be run in parallel with / mirror the [official HUMAnN v3 tutorial](https://github.com/biobakery/biobakery/wiki/humann3)
- ❓️ If you have questions about HUMAnN itself, please direct them to the [bioBakery help forum](https://forum.biobakery.org/c/Microbial-community-profiling/HUMAnN)
- 🤔 If you have questions about using the MetaPhlAn tools in julia, [please open an issue](https://github.com/BioJulia/BiobakeryUtils.jl/issues/new/choose),
  or start a discussion over on [`Microbiome.jl`](https://github.com/BioJulia/Microbiome.jl/discussions/new)!
- 📔 For a function / type reference, [jump to the bottom](#Functions-and-Types)

## Installation and setup

If you haven't already,
check out the ["Getting Started"](@ref getting-started) page to install julia,
create an environment and install BiobakeryUtils.jl,
and hook up or install the HUMAnN v3 command line tools.

This tutorial assumes:

1. You are running julia v1.6 or greater
2. You have activated a julia Project that has `BiobakeryUtils.jl` installed
3. The `humann` python package is installed, and accessible from your `PATH`.

If any of those things aren't true, or you don't know if they're true,
go back to ["Getting Started"](@ref getting-started) to see if you skipped a step.
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
use the [`humann_profile`](@ref) function:

```julia-repl
julia> gfs = humann_profile("demo_fastq/demo_genefamilies.tsv")
Microbiome.CommunityProfile{Float64, Microbiome.GeneFunction, Microbiome.MicrobiomeSample} with 589 things in 1 places

Sample names:
UNMAPPED, UniRef90_G1UL42, UniRef90_I9QXW8...UniRef90_A6LH06, UniRef90_D0TRR5

Feature names:
demo_genefamilies
```

HUMAnN generates "stratified" gene function profiles - 
in other words, each gene function is also split into the species that contributed it.
By default, `humann_profile` skips the stratified rows (they can get big!):

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

There are several ways to manipulate `CommunityProfile`s,
both using julia and using utilities provided by `humann`.

One example of the former is using `filter`,
which takes a boolean function as the first argument,
and returns a new `CommunityProfile` containing only
rows that returned `true`. 

For example, given a stratified table like `gfs_strat`,
if you want to get only rows that have a taxon associated with them,
you can do:

```julia-repl
julia> gfs_strat_only = filter(hastaxon, gfs_strat)
CommunityProfile{Float64, GeneFunction, MicrobiomeSample} with 827 features in 1 samples

Feature names:
UniRef90_G1UL42, UniRef90_I9QXW8, UniRef90_A0A174QBF2...UniRef90_D0TRR5, UniRef90_D0TRR5

Sample names:
demo_genefamilies
```

Uh oh! We've now lost the "UNMAPPED" row,
which means that we won't have the reads that couldn't be mapped to a gene function represented.
No matter,
we can use julia's [anonymous function](https://docs.julialang.org/en/v1/manual/functions/#man-anonymous-functions)
(also sometimes called "lambda function") syntax
to roll our own function.

In the following example, `gf ->` indicates a function that takes a single argument
(in this case, our `GeneFunction`),
then askes if it's [`name`](@ref) is "UNMAPPED" with `name(gf) == "UNMAPPED"`,
OR (`||` is a short-circuiting OR operator) if it has a taxon:

```julia-repl
julia> gfs_with_unmapped = filter(
                            gf-> name(gf) == "UNMAPPED" || hastaxon(gf),
                            gfs_strat)
CommunityProfile{Float64, GeneFunction, MicrobiomeSample} with 828 features in 1 samples

Feature names:
UNMAPPED, UniRef90_G1UL42, UniRef90_I9QXW8...UniRef90_D0TRR5, UniRef90_D0TRR5

Sample names:
demo_genefamilies
```
### Normalize RPK to relative abundance

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/humann3#31-normalizing-rpks-to-relative-abundance)

Some `humann` utility scripts have convenience functions in `BiobakeryUtils.jl`.
for example, if you want to renormalize your table into relative abundance,
you could use `humann_renorm_table` from the command line,
or call [`humann_renorm`](@ref):

```julia-repl
julia> gfs_renormed = humann_renorm(gfs_strat; units="relab")
Loading table from: /tmp/jl_9WL33H
  Treating /tmp/jl_9WL33H as stratified output, e.g. ['UniRef90_G1UL42', 'Bacteroides_dorei']
CommunityProfile{Float64, GeneFunction, MicrobiomeSample} with 589 features in 1 samples

Feature names:
UNMAPPED, UniRef90_G1UL42, UniRef90_I9QXW8...UniRef90_A6LH06, UniRef90_D0TRR5

Sample names:
demo_genefamilies

julia> abundances(gfs_strat[1:5, 1])
5×1 SparseArrays.SparseMatrixCSC{Float64, Int64} with 5 stored entries:
 17556.0
   333.333
   333.333
   333.333
   333.333

julia> abundances(gfs_renormed[1:5, 1])
5×1 SparseArrays.SparseMatrixCSC{Float64, Int64} with 5 stored entries:
 0.665379
 0.0126335
 0.0126335
 0.00758008
 0.00631673
```

### Regrouping genes to other functional categories

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/humann3#32-regrouping-genes-to-other-functional-categories)

Similarly, if we want to regroup our uniref90s into another gene function category like ecs or KOs,
we can use [`humann_regroup`](@ref)

```julia-repl
julia> gfs_rxn = humann_regroup(gfs_strat, inkind="uniref90", outkind="rxn")
Loading table from: /tmp/jl_SA9rCQ
  Treating /tmp/jl_SA9rCQ as stratified output, e.g. ['UniRef90_G1UL42', 'Bacteroides_dorei']
Loading mapping file from: /home/kevin/.julia/conda/3/envs/biobakery/lib/python3.7/site-packages/humann/tools/../data/pathways/meta
cyc_reactions_level4ec_only.uniref.bz2
Original Feature Count: 589; Grouped 1+ times: 78 (13.2%); Grouped 2+ times: 20 (3.4%)
CommunityProfile{Float64, GeneFunction, MicrobiomeSample} with 174 features in 1 samples

Feature names:
UNMAPPED, UNGROUPED, 1.7.7.2-RXN...UDPNACETYLGLUCOSAMACYLTRANS-RXN, UROGENDECARBOX-RXN

Sample names:
demo_genefamilies

julia> first(features(gfs_strat), 5)
5-element Vector{GeneFunction}:
 GeneFunction("UNMAPPED", missing)
 GeneFunction("UniRef90_G1UL42", missing)
 GeneFunction("UniRef90_G1UL42", Taxon("Bacteroides_dorei", :species))
 GeneFunction("UniRef90_I9QXW8", missing)
 GeneFunction("UniRef90_I9QXW8", Taxon("Bacteroides_dorei", :species))

julia> first(features(gfs_rxn), 5)
5-element Vector{GeneFunction}:
 GeneFunction("UNMAPPED", missing)
 GeneFunction("UNGROUPED", missing)
 GeneFunction("1.7.7.2-RXN", missing)
 GeneFunction("1.8.1.4-RXN", missing)
 GeneFunction("2.4.1.135-RXN", missing)
```

Note - to get other feature types, you may have to download the requisite databases
using `humann_databases` at the command line.
See [Using Conda.jl](@ref)

### Attaching names to features

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/humann3#33-attaching-names-to-features)

You can attach names to features using [`humann_rename`](@ref).


## HUMAnN for multiple samples

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/humann3#42-humann-for-multiple-samples)

You can easily run multiple files in a loop in julia.
First, download the files
(if you already did this [in the MetaPhlAn tutorial](@ref metaphlan-multi), no need to repeat it).

```julia-repl
julia> base_url = "https://github.com/biobakery/biobakery/raw/master/demos/biobakery_demos/data/metaphlan3/input/";

julia> files = [
           "SRS014476-Supragingival_plaque.fasta.gz",
           "SRS014494-Posterior_fornix.fasta.gz",
           "SRS014459-Stool.fasta.gz",
           "SRS014464-Anterior_nares.fasta.gz",
           "SRS014470-Tongue_dorsum.fasta.gz",
           "SRS014472-Buccal_mucosa.fasta.gz"
       ];

julia> for file in files
           download(joinpath(base_url, file), file)
       end
```

Then, just write a normal loop with `humann`:

```julia-repl
julia> for file in files
           humann(file, "hmp_subset")
       end
[ Info: Running command: humann -i SRS014476-Supragingival_plaque.fasta.gz -o hmp_subset
Creating output directory: /home/kevin/my_project/hmp_subset
Output files will be written to: /home/kevin/my_project/hmp_subset
Decompressing gzipped file ...
# ... etc
```

On my decently powerful laptop, this took about 10 min.

To merge them using `humann_join_tables`,
use the convenient julia function, [`humann_join`](@ref):

```julia-repl
julia> humann_join("hmp_subset", "hmp_subset_genefamilies.tsv"; file_name="genefamilies")
Gene table created: /home/kevin/my_project/hmp_subset_genefamilies.tsv
Process(`humann_join_tables -i hmp_subset -o hmp_subset_genefamilies.tsv --file_name genefamilies`, ProcessExited(0))
```

This will write a new file that you can then load with [`humann_profiles`](@ref)

```julia-repl
julia> humann_profiles("hmp_subset_genefamilies.tsv"; stratified=true)

```

Alternatively, you can load each profile into a `CommunityProfile`,
then merge them using the `Microbiome.jl` function `commjoin`:

```julia-repl
# anonymous function passed to filter files that contain "genefamilies"
julia> hmp_files = filter(f-> contains(f, "genefamilies"),
                              readdir("hmp_subset"; join=true))
6-element Vector{String}:
 "hmp_subset/SRS014459-Stool_genefamilies.tsv"
 "hmp_subset/SRS014464-Anterior_nares_genefamilies.tsv"
 "hmp_subset/SRS014470-Tongue_dorsum_genefamilies.tsv"
 "hmp_subset/SRS014472-Buccal_mucosa_genefamilies.tsv"
 "hmp_subset/SRS014476-Supragingival_plaque_genefamilies.tsv"
 "hmp_subset/SRS014494-Posterior_fornix_genefamilies.tsv"

julia> commjoin(humann_profile.(hmp_files)...)
CommunityProfile{Float64, GeneFunction, MicrobiomeSample} with 1 features in 6 samples

Feature names:
UNMAPPED

Sample names:
SRS014459-Stool_genefamilies, SRS014464-Anterior_nares_genefamilies, SRS014470-Tongue_dorsum_genefamilies...SRS014476-Supragingival
_plaque_genefamilies, SRS014494-Posterior_fornix_genefamilies
```


## Plotting

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/humann3#5-plotting-stratified-functions)

`BiobakeryUtils.jl` does not come with plotting recipes (yet),
but there are several excellent plotting packages that you can use.
Alternatively, you can use the wrapped [`humann_barplot`](@ref) script.

First, download the pcl file used in the HUMAnN tutorial.

```julia-repl
julia> download("https://raw.githubusercontent.com/biobakery/biobakery/master/demos/biobakery_demos/data/humann2/input/hmp_pathabund.pcl", "hmp_pathabund.pcl")
```

### Using humann_barplot

It's probably a good idea to read the tutorial link above that describes the dataset.
here are the equivalent julia commands to generate the plots described there.

```julia-repl
julia> gfs = read_pcl("hmp_pathabund.pcl"; last_metadata="STSite")



julia> humann_barplot(gfs, "plot1.png"; focal_metadata="STSite", focal_feature="METSYN-PWY")
Process(`humann_barplot --i /tmp/jl_tKWIfW -o plot1.png --last-metadata STSite --focal-metadata STSite --focal-feature METSYN-PWY`,

julia> humann_barplot(gfs, "plot2.png"; focal_metadata="STSite", focal_feature="METSYN-PWY", 
                      sort="sum")
Process(`humann_barplot --i /tmp/jl_vF6GHe -o plot2.png --last-metadata STSite --focal-metadata STSite --focal-feature METSYN-PWY -

julia> humann_barplot(gfs, "plot3.png"; focal_metadata="STSite", focal_feature="METSYN-PWY",
                      sort=["sum", "metadata"],
                      scaling="logstack")
Process(`humann_barplot --i /tmp/jl_VVl3zD -o plot3.png --last-metadata STSite --focal-metadata STSite --focal-feature METSYN-PWY -
-sort sum metadata --scaling logstack`, ProcessExited(0))

julia> humann_barplot(gfs, "plot4.png"; focal_metadata="STSite", focal_feature="COA-PWY",
                      sort="sum")
Process(`humann_barplot --i /tmp/jl_XePIBD -o plot4.png --last-metadata STSite --focal-metadata STSite --focal-feature COA-PWY --so
rt sum`, ProcessExited(0))

julia> humann_barplot(gfs, "plot5.png"; focal_metadata="STSite", focal_feature="COA-PWY",
                      sort="braycurtis",
                      scaling="logstack",
                      as_genera=true,
                      remove_zeros=true)
```

On the last call, notice that "flag arguments" (eg `--as-genera`)
that don't take arguments on the command line must be set to `true` in the julia version.

### Using julia plotting


Use the [`read_pcl`](@ref) function to load the pcl file into julia,
which will add all of the metadata
encoded in the PCL to the resulting `CommunityProfile`


```julia-repl
julia> gfs = read_pcl("hmp_pathabund.pcl", last_metadata="STSite")
CommunityProfile{Float64, GeneFunction, MicrobiomeSample} with 5606 features in 378 samples

Feature names:
1CMET2-PWY: N10-formyl-tetrahydrofolate biosynthesis, 1CMET2-PWY: N10-formyl-tetrahydrofolate biosynthesis, 1CMET2-PWY: N10-formyl-
tetrahydrofolate biosynthesis...VALSYN-PWY: L-valine biosynthesis, VALSYN-PWY: L-valine biosynthesis

Sample names:
SRS011084, SRS011086, SRS011090...SRS058213, SRS058808



julia> first(samples(gfs))
MicrobiomeSample("SRS011084", {:STSite = "Stool"})
```

For plotting, I tend to use [Makie](https://github.com/JuliaPlots/Makie.jl),
but there are [many other options](https://juliahub.com/ui/Search?q=plotting&type=packages).


## Functions and types

```@autodocs
Modules = [BiobakeryUtils]
Pages = ["humann.jl"]
```
