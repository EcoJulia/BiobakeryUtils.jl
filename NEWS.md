# News for BioakeryUtils.jl

## Unreleased

- Add `read_metaphlan` and `read_humann` raw table readers for paths and decompressed IO.
- Support gzip and XZ paths in MetaPhlAn and HUMAnN profile readers.
- Add `humann_profiles(paths)` and construct multi-file profiles directly using a shared feature map.
- Build merged HUMAnN sparse matrices in bulk and preserve supplied sample metadata.

## v0.5.0 Major overhaul

This version brings a whole host of developments that should make it actually usable.
See the [release notes](https://github.com/EcoJulia/BiobakeryUtils.jl/releases/tag/v0.5.0) for details.

See also the JOSS manuscript over at [`Microbiome.jl`](https://github.com/EcoJulia/Microbiome.jl): https://github.com/openjournals/joss-reviews/issues/3876

## Versions 0.2-0.4

Incremental changes, trying to settle on what this package is for.

## v0.1.0 Liberation from Microbiome.jl

This package started off in [Microbiome.jl](https://github.com/BioJulia/Microbiome.jl/).
It's here now - hopefully this will make it easier to keep maintained.
