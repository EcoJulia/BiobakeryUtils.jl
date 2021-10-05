# MetaPhlAn Tutorial with BiobakeryUtils.jl

- 🗒️ This tutorial is meant to be run in parallel with / mirror the [official MetaPhlAn v3 tutorial](https://github.com/biobakery/biobakery/wiki/metaphlan3)
- ❓️ If you have questions about MetaPhlAn itself, please direct them to the [bioBakery help forum](https://forum.biobakery.org/c/Microbial-community-profiling/MetaPhlAn)
- 🤔 If you have questions about using the MetaPhlAn tools in julia, [please open an issue](https://github.com/BioJulia/BiobakeryUtils.jl/issues/new/choose)),
  or start a discussion over on [`Microbiome.jl`](https://github.com/BioJulia/Microbiome.jl/discussions/new))!
- 📔 For a function / type reference, [jump to the bottom](#Functions-and-Types)

## Installation and setup

If you haven't already,
check out the ["Getting Started"](gettingstarted) page to install julia,
create an environment and install BiobakeryUtils.jl,
and hook up or install the MetaPhlAn v3 command line tools.

This tutorial assumes:

1. You are running julia v1.6 or greater
2. You have activated a julia Project that has `BiobakeryUtils.jl` installed
3. The `metaphlan` python package is installed, and accessible from your `PATH`.

If any of those things aren't true, or you don't know if they're true,
go back to ["Getting Started"](gettingstarted) to see if you skipped a step.
If you're still confused, please ask (see 3rd bullet point at the top)!

### Bowtie2 database

The first time you run `metaphlan`, it needs to download

## Input files

[Official tutorial link](https://github.com/biobakery/biobakery/wiki/metaphlan3#input-files)

Some example files you can use to run this tutorial are available from the MetaPhlAn repo,
and can be downloaded using the `Downloads` standard library in julia:

```@repl
using Downloads: download

base_url = "https://github.com/biobakery/biobakery/raw/master/demos/biobakery_demos/data/metaphlan3/input/";

files = [
    "SRS014476-Supragingival_plaque.fasta.gz",
    "SRS014494-Posterior_fornix.fasta.gz",
    "SRS014459-Stool.fasta.gz",
    "SRS014464-Anterior_nares.fasta.gz",
    "SRS014470-Tongue_dorsum.fasta.gz",
    "SRS014472-Buccal_mucosa.fasta.gz"
];

mkdir("inputs")

for file in files
    download(joinpath(base_url, file), joinpath("inputs", file))
end

readdir("inputs")
```

## Run a single sample

- https://github.com/biobakery/biobakery/wiki/metaphlan3#run-a-single-sample
- for now, use `run(cmd)`

## Output files

- https://github.com/biobakery/biobakery/wiki/metaphlan3#output-files
- load output with `metaphlan_profile`
- investigate with various functions (try to show similar things as tutorial)

## Run on multiple cores

- https://github.com/biobakery/biobakery/wiki/metaphlan3#run-on-multiple-cores

## Run multiple samples

- https://github.com/biobakery/biobakery/wiki/metaphlan3#run-multiple-samples

## Merge outputs

- https://github.com/biobakery/biobakery/wiki/metaphlan3#merge-outputs
- use `metaphlan_profile` in loop and then `commjoin`
- use `metaphlan_profiles`

## Visualize results

- https://github.com/biobakery/biobakery/wiki/metaphlan3#visualize-results
- Kevin should probably handle this part

## Functions and Types

```@autodocs
Modules = [BiobakeryUtils]
Pages = ["metaphlan.jl"]
```
