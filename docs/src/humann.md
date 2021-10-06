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

- load gene families file with `humann_profile`
- look at contents
- filter on stratified, unstratified

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
