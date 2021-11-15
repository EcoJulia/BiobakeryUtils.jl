![Microbiome.jl logo](https://github.com/EcoJulia/Microbiome.jl/blob/master/logo.png)

# BiobakeryUtils.jl

[![status](https://joss.theoj.org/papers/450fa18f47932c5fd3b837edeac91440/status.svg)](https://joss.theoj.org/papers/450fa18f47932c5fd3b837edeac91440) ![EcoJulia maintainer: kescobo](https://img.shields.io/badge/EcoJulia%20Maintainer-kescobo-blue.svg)

**Latest Release:**

[![Latest Release](https://img.shields.io/github/release/EcoJulia/BiobakeryUtils.jl.svg)](https://github.com/EcoJulia/BiobakeryUtils.jl/releases/latest)

[![](https://img.shields.io/badge/docs-stable-blue.svg)](http://docs.ecojulia.org/BiobakeryUtils.jl/stable/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/EcoJulia/BiobakeryUtils.jl/blob/master/LICENSE)
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)


**Development Status**

[![CI](https://github.com/EcoJulia/BiobakeryUtils.jl/workflows/CI/badge.svg)](https://github.com/EcoJulia/BiobakeryUtils.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/EcoJulia/BiobakeryUtils.jl/branch/main/graph/badge.svg?token=F6TAE5dppU)](https://codecov.io/gh/EcoJulia/BiobakeryUtils.jl)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](http://docs.ecojulia.org/BiobakeryUtils.jl/latest/)

## Description

`BiobakeryUtils.jl` is a companion package for [`Microbiome.jl`](https://github.com/EcoJulia/Microbiome.jl)
for interacting with the [bioBakery](https://github.com/biobakery/biobakery/wiki)
family of computational tools
authored by the [Huttenhower Lab](http://huttenhower.sph.harvard.edu/) at Harvard.

BiobakeryUtils.jl reexports all functionality from `Microbiome.jl`,
so you never need to do both `using BiobakeryUtils` _and_ `using Microbiome.jl`.

## Installation

Install BiobakeryUtils.jl from the Julia REPL:

```
] add BiobakeryUtils
```

If you are interested in the cutting edge of the development, please check out
the master branch to try new features before release.

```
] add BiobakeryUtils#main
```
