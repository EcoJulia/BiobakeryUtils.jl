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
If you run into problems, you can [open an issue](https://github.com/BioJulia/BiobakeryUtils.jl/issues/new/choose) on this repository,
or start a discussion over on [`Microbiome.jl`](https://github.com/BioJulia/Microbiome.jl/discussions/new).

## Installing julia

If this is your first time using julia,
you'll need to install it by going to the [julia downloads page](https://julialang.org/downloads/)
and following the instructions for your platform.
`BiobakeryUtils.jl` should work on any julia version >= 1.6.0.

Alternatively, you can you [`jill.py`](https://github.com/johnnychen94/jill.py),
which is an easy-to-use python utility for installing julia.

### Launching julia from the terminal

If you download the "app" versions of julia from the downloads page above,
you may also want to add `julia` to your shell's `$PATH`
so that you can launch it from your terminal.
For windows users, you can look [look here](https://julialang.org/downloads/platform/#adding_julia_to_path_on_windows_10)
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

## Using `bioBakery` command line tools

Some functions provided by this package (eg [`humann_regroup`](@ref) and [`humann_rename`](@ref)),
require the appropriate `bioBakery` tools to be installed and accessible from the julia `shell` environment.
The easiest way to do this is to use `Conda.jl`,
though other installation methods are possible as well.

### Using a previous installation

If you have a previous installation of `metaphlan` and/or `humann`,
you can tell julia to use them by modifying the `$PATH` environment variable.

Environment variables in julia are stored in a `Dict` called `ENV`.
For example, the `$PATH` variable in Unix tells the shell where to look
for executable programs, and is available in julia using `ENV["PATH"]`

```@repl conda
ENV["PATH"]
```

If you launch julia from the shell,
this variable is automatically populated with the same `$PATH`,
so if you can access `humann` or `metaphlan` from your shell,
then launch julia, you should be all set
(eg, if you've installed them with miniconda, and you do `conda activate envname`,
then launch julia from the same shell, they should already be available).

If not, you need to identify where `humann` or `metaphlan` executables are located,
then add that location to `ENV["PATH"]` (delimeted by `:`).
For example, if the `humann` executable is found at `/home/kevin/.local/bin`,
you would run:

```@repl conda
ENV["PATH"] = ENV["PATH"] * ":" * "/home/kevin/.local/bin"
```

If you don't know where your installation is located,
from the terminal, you can use the `which` command:

```sh
$ which humann
/home/kevin/.local/bin/humann
```

### [Using Conda.jl](@id using-conda)

If you don't have a previous installation, you can use [`Conda.jl`](https://github.com/JuliaPy/Conda.jl) to install the necessary tools.

This can be done automatically for you using [`BiobakeryUtils.install_deps()`](@ref).

```julia-repl
julia> BiobakeryUtils.install_deps()
[ Info: Running conda create -y -p /home/kevin/.julia/conda/3/envs/BiobakeryUtils in root environment
Collecting package metadata (current_repodata.json): done
Solving environment: done

## Package Plan ##

  environment location: /home/kevin/.julia/conda/3/envs/BiobakeryUtils



Preparing transaction: done
Verifying transaction: done
Executing transaction: **done**
# ... etc
```

```@docs
BiobakeryUtils.install_deps()
```

Or you can do it manually.
First install `Conda.jl` in your environment using the Pkg REPL
(accessible by typing `]` in the julia REPL - press `<backspace>` to get back to the regular REPL).

```plaintext
$ cd my_project/

$ julia --project
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.6.1 (2021-04-23)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia> # press ']'

(my_project) pkg> add Conda
    Updating registry at `~/.julia/registries/General`
   Resolving package versions...
    Updating `~/.julia/dev/BiobakeryUtils/my_project/Project.toml`
  [8f4d0f93] + Conda v1.5.2
    Updating `~/.julia/dev/BiobakeryUtils/my_project/Manifest.toml`
  [8f4d0f93] + Conda v1.5.2
  [682c06a0] + JSON v0.21.2
  [69de0a69] + Parsers v2.0.4
  [81def892] + VersionParsing v1.2.0
  [ade2ca70] + Dates
  [a63ad114] + Mmap
  [de0858da] + Printf
  [4ec0a83e] + Unicode

julia> using Conda
```

First, you'll need to add "channels" to a new Conda environment.
The order here is important.
Assuming you want your environment to be called `biobakery`:

```julia-repl
julia> Conda.add_channel("bioconda", :biobakery)
┌ Info: Running conda config --add channels bioconda --file /home/kevin/.julia/conda/3/envs/biobakery/condarc-julia.yml --force
└ in biobakery environment
# ...

julia> Conda.add_channel("conda-forge", :biobakery)
┌ Info: Running conda config --add channels conda-forge --file /home/kevin/.julia/conda/3/envs/biobakery/condarc-julia.yml
└ --force in biobakery environment
# ...

julia> Conda.add("humann", :biobakery)
[ Info: Running conda install -y -c bioconda humann in biobakery environment
Collecting package metadata (current_repodata.json): done
Solving environment: done
# ...

julia> Conda.add("metaphlan", :biobakery; channel="bioconda")
[ Info: Running conda install -y -c bioconda metaphlan in biobakery environment
Collecting package metadata (current_repodata.json): done
Solving environment: done
# ...
```

[![asciicast](https://asciinema.org/a/bahBYyfDyLoETR0qf1cQl7Stb.svg)](https://asciinema.org/a/bahBYyfDyLoETR0qf1cQl7Stb)

By default, `Conda.jl` puts environments into `~/.julia/conda/envs/<env name>/bin`,
which you can get with `Conda.bin_dir()`, so in this case, you'd next want to run

```@repl
ENV["PATH"] = ENV["PATH"] * ":" * Conda.bin_dir(:biobakery)
```

Note: if you need to manually edit `ENV["PATH"]` like this,
you'll need to do this each time you load julia.
To get around this, you can modify you shell's `$PATH` variable,
or use [`direnv`](https://direnv.net) to set it on a per-directory basis.

## Using MetaPhlAn and HUMAnN

You should now be ready to start using MetaPhlAn and HUMAnN from julia!
Take a look at the [MetaPhlAn tutorial](@ref metaphlan-tutorial)
or [HUMAnN tutorial](@ref humann-tutorial)
for next steps.
