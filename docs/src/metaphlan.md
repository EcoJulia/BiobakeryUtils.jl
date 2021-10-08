```@meta
CurrentModule = BiobakeryUtils
DocTestSetup  = quote
    using BiobakeryUtils
    using BiobakeryUtils.Conda
    BiobakeryUtils.install_deps()
    ENV["PATH"] = ENV["PATH"] * Conda.bind_dir(:BiobakeryUtils)
end
```
# [MetaPhlAn Tutorial with BiobakeryUtils.jl](@id metaphlan-tutorial)


- 🗒️ This tutorial is meant to be run in parallel with / mirror the [official MetaPhlAn v3 tutorial](https://github.com/biobakery/biobakery/wiki/metaphlan3)
- ❓️ If you have questions about MetaPhlAn itself, please direct them to the [bioBakery help forum](https://forum.biobakery.org/c/Microbial-community-profiling/MetaPhlAn)
- 🤔 If you have questions about using the MetaPhlAn tools in julia, [please open an issue](https://github.com/BioJulia/BiobakeryUtils.jl/issues/new/choose)),
  or start a discussion over on [`Microbiome.jl`](https://github.com/BioJulia/Microbiome.jl/discussions/new))!
- 📔 For a function / type reference, [jump to the bottom](#Functions-and-Types)

## Installation and setup

If you haven't already,
check out the ["Getting Started"](@ref getting-started) page to install julia,
create an environment,xd and install BiobakeryUtils.jl,
and hook up or install the MetaPhlAn v3 command line tools.

This tutorial assumes:

1. You are running julia v1.6 or greater
2. You have activated a julia Project that has `BiobakeryUtils.jl` installed
3. The `metaphlan` python package is installed, and accessible from your `PATH`.

If any of those things aren't true, or you don't know if they're true,
go back to ["Getting Started"](@ref getting-started) to see if you skipped a step.
If you're still confused, please ask (see 3rd bullet point at the top)!

### Bowtie2 database

The first time you run `metaphlan`, it needs to download and unpack the marker database.
If you don't care where this goes, don't worry about it - by default it will go
into a subdirectory of your `conda` environment.

If your home folder has limited space, or you want to install it to a particular location
(eg a faster drive),
you can either pass the kewword argument `bowtie2db="/path/to/location"` to all `metaphlan` commands,
or set the environment variable `METAPHLAN_BOWTIE2_DB`.


## Input files

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/metaphlan3#input-files)

Some example files you can use to run this tutorial are available from the MetaPhlAn repo,
and can be downloaded using the `Downloads` standard library in julia:

```julia-repl
julia> using Downloads: download

julia> base_url = "https://github.com/biobakery/biobakery/raw/master/demos/biobakery_demos/data/metaphlan3/input/";

julia>  files = [
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

julia> readdir()
9-element Vector{String}:
 "Manifest.toml"
 "Project.toml"
 "SRS014459-Stool.fasta.gz"
 "SRS014464-Anterior_nares.fasta.gz"
 "SRS014470-Tongue_dorsum.fasta.gz"
 "SRS014472-Buccal_mucosa.fasta.gz"
 "SRS014476-Supragingival_plaque.fasta.gz"
 "SRS014494-Posterior_fornix.fasta.gz"
```

## Run a single sample

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/metaphlan3#run-a-single-sample)

For convenience, this package has the [`metaphlan()`](@ref) function,
which can be used in your julia scripts to build and call the `metaphlan` command line tool.

For example, rather than call this from the shell:

```sh
$ metaphlan SRS014476-Supragingival_plaque.fasta.gz --input_type fasta > SRS014476-Supragingival_plaque_profile.txt
```

you can instead call this from the julia REPL:

```julia-repl
julia> metaphlan("SRS014476-Supragingival_plaque.fasta.gz",
                 "SRS014476-Supragingival_plaque_profile.tsv"; input_type="fasta")
```

The first time you run this command,
metaphlan will download its database
and build Bowtie2 indices for aligning marker genes.
It may take a while... maybe go for a walk 🙂.
## Output files

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/metaphlan3#output-files)

You can now load this profile using [`metaphlan_profile`](@ref):

```julia-repl
julia> mp = metaphlan_profile("SRS014476-Supragingival_plaque_profile.tsv"; sample="SRS014476")
CommunityProfile{Float64, Taxon, MicrobiomeSample} with 11 features in 1 samples

Feature names:
Bacteria, Actinobacteria, Actinobacteria...Corynebacterium_matruchotii, Rothia_dentocariosa

Sample names:
SRS014476
```

This generates a [`CommunityProfile`](@ref Microbiome.CommunityProfile) type from Microbiome.jl,
which is a matrix-like object with [`MicrobiomeSample`](@ref Microbiome.MicrobiomeSample)s
as column headers,
and [`Taxon`](@ref Microbiome.Taxon)s as row headers.

The samples can be accessed with [`samples`](@ref Microbiome.samples)
or [`samplenames`](@ref Microbiome.samplenames):

```julia-repl
julia> samples(mp)
1-element Vector{MicrobiomeSample}:
 MicrobiomeSample("SRS014476", {})

julia> samplenames(mp)
1-element Vector{String}:
 "SRS014476"
```

Notice that in addition to the sample name ("SRS014476"),
there's an additional field - that's a metadata dictionary
that we can add values to.

```julia-repl
julia> plaque = first(samples(mp))
MicrobiomeSample("SRS014476", {})

julia> set!(plaque, :STSite, "Supragingival Plaque")
MicrobiomeSample("SRS014476", {:STSite = "Supragingival Plaque"})
```

The taxa (Microbiome.jl uses the generic term "features") can be accessed
with [`features`](@ref Microbiome.features)
or [`featurenames`](@ref Microbiome.featurenames):

```julia-repl
julia> features(mp)
11-element Vector{Taxon}:
 Taxon("Bacteria", :kingdom)
 Taxon("Actinobacteria", :phylum)
 Taxon("Actinobacteria", :class)
 Taxon("Corynebacteriales", :order)
 Taxon("Micrococcales", :order)
 Taxon("Corynebacteriaceae", :family)
 Taxon("Micrococcaceae", :family)
 Taxon("Corynebacterium", :genus)
 Taxon("Rothia", :genus)
 Taxon("Corynebacterium_matruchotii", :species)
 Taxon("Rothia_dentocariosa", :species)

julia> featurenames(mp)
11-element Vector{String}:
 "Bacteria"
 "Actinobacteria"
 "Actinobacteria"
 "Corynebacteriales"
 "Micrococcales"
 "Corynebacteriaceae"
 "Micrococcaceae"
 "Corynebacterium"
 "Rothia"
 "Corynebacterium_matruchotii"
 "Rothia_dentocariosa"
```



## Run on multiple cores

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/metaphlan3#run-on-multiple-cores)

Other keywords can be passed to `metaphlan()` as well.
For example, to speed things up a bit,
try `nproc=4`:

```julia-repl
julia> metaphlan("SRS014459-Stool.fasta.gz",
                        "SRS014459-Stool_profile.tsv"; input_type="fasta", nproc=4)
[ Info: Running command: metaphlan SRS014459-Stool.fasta.gz SRS014459-Stool_profile.tsv --input_type fasta --nproc 4
# ... 
```

## [Run multiple samples](@id metaphlan-multi)

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/metaphlan3#run-multiple-samples)

You can use julia to run `metaphlan` in a loop to do the rest of the files.
Here, we find the output path by replacing `.fasta.gz` with `_profile.tsv`,
then check if it exists already, and `continue` if it does
(`&&` means "AND" - if `isfile(prof)` is `true`, then it will do the thing on the right).

```julia-repl
julia> for f in files
           prof = replace(f, ".fasta.gz"=>"_profile.tsv")
           isfile(prof) && continue
           metaphlan(f, prof; input_type="fasta", nproc=4)
       end
┌ Info: Running command: metaphlan SRS014494-Posterior_fornix.fasta.gz SRS014494-Posterior_fornix_profile.tsv --input_type fasta
└ --nproc 4
```

## Merge outputs

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/metaphlan3#merge-outputs)

- use `metaphlan_profile` in loop and then `commjoin`
- use `metaphlan_profiles`

## Visualize results

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/metaphlan3#visualize-results)

- Kevin should probably handle this part

## Functions and Types

```@autodocs
Modules = [BiobakeryUtils]
Pages = ["metaphlan.jl"]
```
