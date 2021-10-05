# HUMAnN Tutorial with BiobakeryUtils.jl

- 🗒️ This tutorial is meant to be run in parallel with / mirror the [official HUMAnN v3 tutorial](https://github.com/biobakery/biobakery/wiki/humann3)
- ❓️ If you have questions about MetaPhlAn itself, please direct them to the [bioBakery help forum](https://forum.biobakery.org/c/Microbial-community-profiling/HUMAnN)
- 🤔 If you have questions about using the MetaPhlAn tools in julia, [please open an issue](https://github.com/BioJulia/BiobakeryUtils.jl/issues/new/choose),
  or start a discussion over on [`Microbiome.jl`](https://github.com/BioJulia/Microbiome.jl/discussions/new)!
- 📔 For a function / type reference, [jump to the bottom](#Functions-and-Types)

## Getting started

- Installation of julia
- Installation of humann with Conda
- Using an existing humann installation

## Running HUMAnN

- https://github.com/biobakery/biobakery/wiki/humann3#2-metagenome-functional-profiling
- For now, run command with `run(cmd)`

## Default outputs

- https://github.com/biobakery/biobakery/wiki/humann3#23-humann-default-outputs
- load gene families file with `humann_profile`
- look at contents
- filter on stratified, unstratified

## Manipulating tables

- https://github.com/biobakery/biobakery/wiki/humann3#3-manipulating-humann-output-tables
- Do all of this in CommProfile

### Normalize RPK to relative abundance

- https://github.com/biobakery/biobakery/wiki/humann3#31-normalizing-rpks-to-relative-abundance

### Regrouping genes to other functional categories

- https://github.com/biobakery/biobakery/wiki/humann3#32-regrouping-genes-to-other-functional-categories
- use `humann_regroup`

### Attaching names to features

- https://github.com/biobakery/biobakery/wiki/humann3#33-attaching-names-to-features
- use `humann_rename`

## HUMAnN for multiple samples

- https://github.com/biobakery/biobakery/wiki/humann3#42-humann-for-multiple-samples

## Plotting

- https://github.com/biobakery/biobakery/wiki/humann3#5-plotting-stratified-functions
- Kevin should do this
## Functions and types

```@autodocs
Modules = [BiobakeryUtils]
Pages = ["humann.jl"]
```
