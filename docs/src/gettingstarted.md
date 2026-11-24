```@meta
CurrentModule = BiobakeryUtils
```

# [Getting Started](@id getting-started)

This is a package for the [julia programming language](http://julialang.org),
designed for working with the [bioBakery](https://github.com/biobakery/biobakery) family of tools
for metagenomic analysis of microbial communities.
Currently, we support [`MetaPhlAn`](https://github.com/biobakery/MetaPhlAn) and [`HUMAnN`](https://github.com/biobakery/HUMAnN).

Read on to learn how to install the package and use it
to begin using it to uncover insights about your microbial community data!
If you run into problems, you can [open an issue](https://github.com/EcoJulia/BiobakeryUtils.jl/issues/new/choose) on this repository,
or start a discussion over on [`Microbiome.jl`](https://github.com/EcoJulia/Microbiome.jl/discussions/new).

## Installing julia

If this is your first time using julia,
you'll need to install it by going to the [julia downloads page](https://julialang.org/downloads/)
and following the instructions for your platform.
`BiobakeryUtils.jl` should work on any julia version >= 1.6.0.

Alternatively, you can use [`jill.py`](https://github.com/johnnychen94/jill.py),
which is an easy-to-use python utility for installing julia.

### Launching julia from the terminal

If you download the "app" versions of julia from the downloads page above,
you may also want to add `julia` to your shell's `$PATH`
so that you can launch it from your terminal.
For windows users, you can [look here](https://julialang.org/downloads/platform/#adding_julia_to_path_on_windows_10)
for instructions.
Mac users, [see here](https://julialang.org/downloads/platform/#optional_add_julia_to_path)
for instructions.

## Making a project

In julia, it's typically a good idea to use ["projects"](https://pkgdocs.julialang.org/v1/environments/)
to organize your package dependencies
(this is similar to "environments" that `conda` uses).

To do this, make a directory and "activate" it in the julia Pkg REPL.

```sh
$ mkdir my_project

$ cd my_project

$ julia

               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.6.1 (2021-04-23)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia> # press ] to enter the Pkg REPL

(@v1.6) pkg> activate .
  Activating new environment at `~/my_project/Project.toml`

(my_project) pkg> # press backspace to get back to julia REPL

julia>
```

[![asciicast](https://asciinema.org/a/440135.svg)](https://asciinema.org/a/440135)

So far, this is still just an empty directory,
but you can also use the Pkg REPL to install packages, like `BiobakeryUtils.jl`.

```sh
(my_project) pkg> add BiobakeryUtils
```

[![asciicast](https://asciinema.org/a/8vMgAdlGV63VztAGhUAlGQ5ai.svg)](https://asciinema.org/a/8vMgAdlGV63VztAGhUAlGQ5ai)

Once this process completes, the directory will now contain a `Project.toml` file
that contains `BiobakeryUtils.jl` as a dependency,
and a `Manifest.toml` file that contains all of the exact info about
dependencies installed for this environment.

In the future, you can launch julia with the environment already activated
using `julia --project` if your working directory is `my_project/`,
or `julia --project=<path to project>` if you're in a different working directory
(eg. `julia --project=~/my_project` if `my_project/` is in the home directory).

## Installing bioBakery command line tools

`BiobakeryUtils.jl` focuses on loading and analyzing output from the bioBakery tools in julia.
Running the tools themselves (MetaPhlAn, HUMAnN) requires a separate installation
of the Python bioBakery packages.

The recommended approach is to install them via conda/mamba following the
[official bioBakery installation guide](https://github.com/biobakery/MetaPhlAn/wiki/MetaPhlAn-4#installation).
Once installed, launch julia from the same shell where the tools are available,
and they will be accessible via `ENV["PATH"]`.

## Using MetaPhlAn and HUMAnN

You should now be ready to start using MetaPhlAn and HUMAnN output from julia!
Take a look at the [MetaPhlAn tutorial](@ref metaphlan-tutorial)
or [HUMAnN tutorial](@ref humann-tutorial)
for next steps.

## Still having issues?

If you run into problems,
please [open an issue](https://github.com/EcoJulia/BiobakeryUtils.jl/issues/new/choose)
or start a discussion over on [`Microbiome.jl`](https://github.com/EcoJulia/Microbiome.jl/discussions/new).
