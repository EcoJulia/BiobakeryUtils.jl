# Using `bioBakery` command line tools

Some functions provided by this package (eg [`humann_regroup_table`](@ref) and [`humann_rename_table`](@ref)),
require the appropriate `bioBakery` tools to be installed and accessible from the julia `shell` environment.
The easiest way to do this is to use `Conda.jl`,
though other installation methods are possible as well.

## Using a previous installation

Environmental variables in julia are stored in a `Dict` called `ENV`.
For example, the `\$PATH` variable in Unix tells the shell where to look
for executable programs, and is available in julia using `ENV["PATH"]`

```@repl conda
ENV["PATH"]
```

This variable is automatically populated with the `\$PATH` variable
from the shell from which you launched julia,
so if you can access `humann` or `metaphlan` from your shell,
then launch julia, you should be all set.

If not, you need to identify where `humann` or `metaphlan` executables are located,
then add that location to `ENV["PATH"]` (delimeted by `:`).
For example, if the `humann` executable is found at `/home/kevin/.local/bin`,
you would run:

```@repl conda
ENV["PATH"] = ENV["PATH"] * ":" * "/home/kevin/.local/bin"
```

## Using Conda

If you don't have a previous installation, you can use `Conda.jl` to install the necessary tools.
To do this, first install `Conda.jl` in your environment using the Pkg REPL
(accessible by typing `]` in the julia REPL - press <backspace> to get back to the regular REPL).

```plaintext
❯ mkdir my_project

❯ cd my_project/

❯ julia
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.6.1 (2021-04-23)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia> # press ']'

(@v1.6) pkg> activate .
  Activating new environment at `~/.julia/dev/BiobakeryUtils/my_project/Project.toml`

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

julia> Conda.add("humann", :biobakery; channel="bioconda")
[ Info: Running conda install -y -c bioconda humann in biobakery environment
Collecting package metadata (current_repodata.json): done
Solving environment: done
# ...
```

By default, `Conda.jl` puts environments into `~/.julia/conda/envs/<env name>`,
so in this case, you'd next want to run

```@repl
ENV["PATH"] = ENV["PATH"] * ":" * expanduser("~/.julia/conda/envs/biobakery/bin")
```
