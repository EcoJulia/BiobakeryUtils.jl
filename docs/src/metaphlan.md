# MetaPhlAn Tutorial with BiobakeryUtils.jl

- 🗒️ This tutorial is meant to be run in parallel with / mirror the [official MetaPhlAn v3 tutorial]([metaphlan])
- ❓️ If you have questions about MetaPhlAn itself, please direct them to the [bioBakery help forum]([bioBakeryhelp])
- 🤔 If you have questions about using the MetaPhlAn tools in julia, [please open an issue]([issues]),
  or start a discussion over on [`Microbiome.jl`]([discussions])!
- 📔 For a function / type reference, [jump to the bottom](#Functions-and-Types)

## Getting started

- Installation of julia
- Installation of metaphlan with Conda
- Using an existing metaphlan installation

## Input files

- https://github.com/biobakery/biobakery/wiki/metaphlan3#input-files

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
