# News for BiobakeryUtils.jl

## v0.8.0

### Breaking changes

- Remove Conda-based installation, environment management, and command-line tool
  wrappers, including `metaphlan`, `humann`, and KneadData helpers. Run the tools
  outside Julia and use this package to read their outputs.

### Readers and performance

- Support CSV 1.3, including PCL metadata loading with its supported parsing keywords.

- Add `read_metaphlan` and `read_humann` raw table readers for paths and decompressed IO.
- Support gzip and XZ paths in MetaPhlAn and HUMAnN profile readers.
- Select MetaPhlAn relative abundance by its named header, supporting tables with
  extra or reordered columns while retaining support for legacy tables.
- Add `humann_profiles(paths)` and construct multi-file profiles directly using a shared feature map.
- Build merged HUMAnN sparse matrices in bulk and preserve supplied sample metadata.
- Accept Microbiome 0.11 and ReTest 0.4, including Julia 1.13 support.

### Documentation and maintenance

- Rewrite getting-started and profile-loading documentation around reading existing
  outputs, and remove tool-running tutorials from the documentation build.
- Update Documenter to version 1, format source with Runic, and refresh CI and
  coverage reporting. Correct the tutorial data URL and add citation metadata.
- Use ReTest 0.4.3, Runic 1.13, and Documenter 1.20 for development checks;
  refresh GitHub Actions and use Dependabot for Julia and action dependencies.

## v0.7.0

- Support Microbiome 0.10 as well as 0.9.4, replacing removed `metadata()` calls
  with `get()` when exporting HUMAnN tables and preparing bar plots.
- Update MetaPhlAn examples for the sample-name column in metadata tables and
  correct profile-size tests.
- Add the JuliaCon 2022 tutorial and remove obsolete compiled-file terminology.

## v0.6.0

- Update for Microbiome 0.9's breaking API changes and require that release series.
- Allow CSV 0.10 alongside 0.8 and 0.9.
- Move package tests to ReTest and include Microbiome's inline tests.

## v0.5.5

- Add KneadData execution, database-download, and read-count-table wrappers, with
  tutorial documentation and example inputs.
- Install KneadData through the existing Conda setup and support excluding
  separately handled options from command-line keyword conversion.

## v0.5.4

- Correct environment names, setup instructions, and documentation links.
- Refresh contribution instructions and add the Zenodo release badge.

## v0.5.3

- Update version metadata; no source-code changes from v0.5.2.

## v0.5.2

- Correct the latest-release badge link in the README.

## v0.5.1

- Fix documentation deployment, README links, and HUMAnN tutorial typos.

## v0.5.0 Major overhaul

This version brings a whole host of developments that should make it actually usable.
See the [release notes](https://github.com/EcoJulia/BiobakeryUtils.jl/releases/tag/v0.5.0) for details.

See also the JOSS manuscript over at [`Microbiome.jl`](https://github.com/EcoJulia/Microbiome.jl): https://github.com/openjournals/joss-reviews/issues/3876

## Versions 0.2-0.4

Incremental changes, trying to settle on what this package is for.

## v0.1.0 Liberation from Microbiome.jl

This package started off in [Microbiome.jl](https://github.com/BioJulia/Microbiome.jl/).
It's here now - hopefully this will make it easier to keep maintained.
