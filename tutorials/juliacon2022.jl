### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 599711e7-ee51-4ca0-94ac-8c1a67f6ac8d
using CSV, BiobakeryUtils, BiobakeryUtils.Conda, Random;

# ╔═╡ e41a1c8a-e51b-475d-8839-83830059c139
md"""
# Welcome to the BiobakeryUtils.jl tutorial 😀

In this tutorial,
we'll learn how to interact with microbial community data
using [`BiobakeryUtils.jl`](https://github.com/EcoJulia/BiobakeryUtils.jl).
bioBakery workflows is a collection of workflows and tasks for executing common 
microbial community analyses using standardized, validated tools and parameters. These tools include:

- Kneadata
- MetaPhlAn 
- HUManN

BiobakeryUtils.jl works mainly with the outputs of MetaPhlAn & HUManN.

If you have any questions or comments,
please start a discussion
or open an issue
on github!
Let's go! 👇️

"""


# ╔═╡ 6600f4d2-f797-4580-8e40-bf3178690995
md"""
## Using the command-line tools

`BiobakeryUtils.jl` has 2 main components:

1. functions for using the `bioBakery` command line tools from within a julia session
2. interfaces for easily loading the file types generated by `bioBakery` tools into `Microbiome.jl`-provided types.

Let's start with the command line tools:
"""

# ╔═╡ 161527c0-d2c9-4ef8-a223-4946b5f0e083
md"""
### Installing bioBakery command line tools

`BiobakeryUtils.jl` works with the [`bioBakery`](https://github.com/biobakery)
suite of command-line tools.
If you already have them installed,
you just need to make sure that they're in your `PATH` environmental variable.
If not, you can install them with `BiobakeryUtils.install_deps()`,
which currently uses `Conda.jl` under the hood.
"""

# ╔═╡ a72172f9-fa8c-450f-a104-bf0636efa4e0
BiobakeryUtils.install_deps()

# ╔═╡ 30a4255b-e147-4c97-8c90-030e55a37d4d
ENV["PATH"] = ENV["PATH"] * ":" *  Conda.bin_dir(:BiobakeryUtils);

# ╔═╡ a7f41ae3-d9b2-4180-bcfb-1edffff7e307
md"""
### Command-line interface design

Each command-line interface function is designed to mimic
the corresponding command line tool in a julia function.
For example, to use `kneaddata` from the command-line, you might run

```sh
$ metaphlan ../test/files/kneaddata/seq1.fastq --output ./seq1_profile.tsv \
			--input_type=fastq \
			--nproc=8

```

The same command using `BiobakeryUtils.jl` is the following.

!!! warning
	Be aware that the first time you run this command, it will take a LONG time,
	not because of julia's TTFP, but because `metaphlan` needs to download and unpack
	the markergene database.

	If you already have the database downloaded somewhere, you can set
	`ENV["METAPHLAN_BOWTIE2_DB"] = "/path/to/db"` to bypass this step
"""

# ╔═╡ 5c74e2c2-e4ba-4ee3-a3c9-1c333185a155
metaphlan("../test/files/kneaddata/seq1.fastq", "./seq1_profile.tsv";
		  input_type="fastq",
		  nproc = 8)

# ╔═╡ 0a77263c-b2fd-4d72-8f73-013294674c53
md"""
In other words, input/output are the first two positional arguments,
and keyword arguments to the cli can be given as julia keyword arguments.
A couple of other features:

- Tools that use multiple inputs can be passed as arrays.
  eg. the first argument to `kneaddata()` can be `"seq1.fastq"` or `["seq1_1.fastq", "seq1_2.fastq"]`
- Tools that use "`-`" in their cli keyword args become "`_`" in julia.
  eg. `humann ... --memory-use minimum` becomes `humann(args... ; memory_use = "minimum")` 
- flags can also be used by passing a `Bool`, eg `humann ... --remove-intermediate-output` from `humann` becomes `humann(args...; remove_intermediate_output=true)`
"""

# ╔═╡ 22ef03e5-0e90-466d-9718-a104002b280f
md""" 

## Interaction with `Microbiome.jl`

In addition to interacting with the CLIs from `bioBakery`,
`BiobakeryUtils.jl` also provides convenience functions
for loading in the tables generated by `humann` and `metaphlan`
into a `CommunityProfile` type from `Microbiome.jl`.

For example, the `metaphlan_profile()` and `humann_profile()` functions
load in single-sample outputs from `metaphlan` and `humann` respectively
into `CommunityProfile`s with correctly-parsed `Taxon` or `GeneFunction` types.
"""

# ╔═╡ 014de4bd-c010-47df-a905-744a5f7a680f
stool = metaphlan_profile("../test/files/metaphlan/SRS014459-Stool_profile.tsv")

# ╔═╡ a3bf38ea-55aa-4c38-9878-50c98d7bcab3
md"""
One can also use the `metaphlan_profiles()` or `humann_profiles()` (note the plurals)
to load a previously-joined profile:
"""

# ╔═╡ 48233970-dd55-4ee4-884c-dfaf641ff32c
hpf = humann_profiles("../test/files/humann/joined.tsv")

# ╔═╡ 05b03cef-3e2f-4ed2-b413-28cdde115a73
samples(hpf)

# ╔═╡ 8e2250d8-440b-4e86-87ca-936484e9547e
md""" 
### Merging files

The file above was created using the `humann` utility `humann_merge_tables` (which has a wrapper in `BiobakeryUtils.jl`, `humann_merge()`.

Alternatively, on can use the `commjoin` function from `Microbiome.jl`
to merge files from within julia.
"""

# ╔═╡ 1ffb9ee7-8962-4020-a483-7f0e51736f4f
mp_files = readdir("../test/files/metaphlan/", join=true)

# ╔═╡ f92b1e50-c942-423d-8bcf-4c37de2778bb
mp_joined = commjoin(
	(metaphlan_profile(f) for f in mp_files)...
)

# ╔═╡ b0cac714-4eb8-43f2-9537-3b39a51507ca
samples(mp_joined)

# ╔═╡ 202b5a3c-404c-4cbd-9d13-038cca3013a2
md"""
### Taxon-Stratification

HUMAnN generates "stratified" gene function profiles - in other words, each gene function is also split into the species that contributed it. By default, human_profile skips the stratified rows (they can get big!).

By default, the `humann_profile[s]()` functions ignore any feature rows containing
taxon-stratified gene functions.
This can be over-ridden by passing the `stratified=true` kwarg.
"""

# ╔═╡ c4f810a3-b381-4b53-a1d5-2998bab98655
h1_strat = humann_profile("../test/files/humann/single_1.tsv", stratified=true)

# ╔═╡ da6e7095-75bc-4100-a634-de6d2d1c7fb7
md"""
Then, if desired,
filtered on rows that have a `taxon` value
using the `hastaxon()` function:
"""

# ╔═╡ 0540ee72-3f67-4e81-a1ec-b5023e08f42b
filter(hastaxon, h1_strat)

# ╔═╡ a38c12ec-1e07-4739-88f7-1d9c02513265
md"""

#### Renormalizing humann data
If we want to renormalize your table into relative abundance, you could use `humann_renorm_table` from the command line, or call `humann_renorm()`

"""

# ╔═╡ 044ceec2-1cd9-4b8a-a4dd-dcc9cc96ac9b
abundances(h1_strat[1:5, 1])

# ╔═╡ d8566a72-a534-4fd5-ba95-93009e3af312
h1_renormed = humann_renorm(h1_strat; units="relab")

# ╔═╡ 5b0c2b43-9867-4d56-b46f-76c204f6bd49
abundances(h1_renormed[1:5, 1])

# ╔═╡ a480ba1b-809f-4760-9eca-f0bba74d2b4b
md"""
#### Regrouping genes to other functional categories

`humann` typically generates profiles using `UniRef` identifiers from uniprot.
These have the benefit of encompassing nearly all gene types,
but they're not very meaningful.
If we want to regroup our uniref90s into another gene function category like ECs or KOs, we can use `humann_regroup()` (which wraps `humann_regroup_table`).
"""

# ╔═╡ d635ed12-2835-4acd-9589-f7b56a7f54da
h1_rxn = humann_regroup(h1_strat, inkind="uniref90", outkind="rxn")

# ╔═╡ b7c65265-e9cc-4a3c-9abb-c1249dd25a38


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BiobakeryUtils = "fa5322f5-bd84-5069-834a-abf3230fb8f8"
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[compat]
BiobakeryUtils = "~0.6.0"
CSV = "~0.10.4"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.2"
manifest_format = "2.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Arpack]]
deps = ["Arpack_jll", "Libdl", "LinearAlgebra", "Logging"]
git-tree-sha1 = "91ca22c4b8437da89b030f08d71db55a379ce958"
uuid = "7d9fca2a-8960-54d3-9f78-7d1dccf2cb97"
version = "0.5.3"

[[deps.Arpack_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "OpenBLAS_jll", "Pkg"]
git-tree-sha1 = "5ba6c757e8feccf03a1554dfaf3e26b3cfc7fd5e"
uuid = "68821587-b530-5797-8361-c406ea357684"
version = "3.5.1+1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BiobakeryUtils]]
deps = ["CSV", "Conda", "Microbiome", "ReTest", "Reexport", "SparseArrays", "Tables"]
git-tree-sha1 = "f7e085edc0296351364f359c3b8cf63bced8ae7c"
uuid = "fa5322f5-bd84-5069-834a-abf3230fb8f8"
version = "0.6.0"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings"]
git-tree-sha1 = "873fb188a4b9d76549b81465b1f75c82aaf59238"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.4"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "9489214b993cd42d17f44c36e359bf6a7c919abf"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.0"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "1e315e3f4b0b7ce40feded39c73049692126cf53"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.3"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "9be8be1d8a6f44b96482c8af52238ea7987da3e3"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.45.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.Conda]]
deps = ["Downloads", "JSON", "VersionParsing"]
git-tree-sha1 = "6e47d11ea2776bc5627421d59cdcc1296c058071"
uuid = "8f4d0f93-b110-5947-807f-2305c1781a2d"
version = "1.7.0"

[[deps.DataAPI]]
git-tree-sha1 = "fb5f5316dd3fd4c5e7c30a24d50643b73e37cd40"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.10.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.Dictionaries]]
deps = ["Indexing", "Random"]
git-tree-sha1 = "7669d53b75e9f9e2fa32d5215cb2af348b2c13e2"
uuid = "85a47980-9c8c-11e8-2b9f-f7ca1fa99fb4"
version = "0.3.21"

[[deps.Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "3258d0659f812acde79e8a74b11f17ac06d0ca04"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.7"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.EcoBase]]
deps = ["RecipesBase"]
git-tree-sha1 = "a4d5b263972e820e780effc2084f92399ba44ee3"
uuid = "a58aae7d-b440-5a11-b283-399458f99aac"
version = "0.1.6"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "129b104185df66e408edd6625d480b7f9e9823a0"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.18"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.Indexing]]
git-tree-sha1 = "ce1566720fd6b19ff3411404d4b977acd4814f9f"
uuid = "313cdc1a-70c2-5d6a-ae34-0150d3930a38"
version = "1.1.1"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "61feba885fac3a407465726d0c330b3055df897f"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.1.2"

[[deps.InlineTest]]
deps = ["Test"]
git-tree-sha1 = "daf0743879904f0ad645ca6594e1479685f158a2"
uuid = "bd334432-b1e7-49c7-a2dc-dd9149e4ebd6"
version = "0.2.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "b3364212fb5d870f724876ffcd34dd8ec6d98918"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.7"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "09e4b894ce6a976c354a69041a04748180d43637"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.15"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Microbiome]]
deps = ["Dictionaries", "Distances", "EcoBase", "MultivariateStats", "ReTest", "SparseArrays", "Statistics", "Tables"]
git-tree-sha1 = "e3393084d259a6c130e85461de1bad059967bc61"
uuid = "3bd8f0ae-a0f2-5238-a5af-e1b399a4940c"
version = "0.9.1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.MultivariateStats]]
deps = ["Arpack", "LinearAlgebra", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "6d019f5a0465522bbfdd68ecfad7f86b535d6935"
uuid = "6f286f6a-111f-5878-ab1e-185364afe411"
version = "0.9.0"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "0044b23da09b5608b4ecacb4e5e6c6332f833a7e"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.3.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.ReTest]]
deps = ["Distributed", "InlineTest", "Printf", "Random", "Sockets", "Test"]
git-tree-sha1 = "dd8f6587c0abac44bcec2e42f0aeddb73550c0ec"
uuid = "e0db7c4e-2690-44b9-bad6-7687da720f89"
version = "0.3.2"

[[deps.RecipesBase]]
git-tree-sha1 = "6bf3f380ff52ce0832ddd3a2a7b9538ed1bcca7d"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.2.1"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "db8481cf5d6278a121184809e9eb1628943c7704"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.13"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "2c11d7290036fe7aac9038ff312d3b3a2a5bf89e"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.4.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "8977b17906b0a1cc74ab2e3a05faa16cf08a8291"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.16"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.VersionParsing]]
git-tree-sha1 = "58d6e80b4ee071f5efd07fda82cb9fbe17200868"
uuid = "81def892-9a0e-5fdd-b105-ffc91e053289"
version = "1.3.0"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─e41a1c8a-e51b-475d-8839-83830059c139
# ╟─6600f4d2-f797-4580-8e40-bf3178690995
# ╟─161527c0-d2c9-4ef8-a223-4946b5f0e083
# ╠═599711e7-ee51-4ca0-94ac-8c1a67f6ac8d
# ╠═a72172f9-fa8c-450f-a104-bf0636efa4e0
# ╠═30a4255b-e147-4c97-8c90-030e55a37d4d
# ╟─a7f41ae3-d9b2-4180-bcfb-1edffff7e307
# ╠═5c74e2c2-e4ba-4ee3-a3c9-1c333185a155
# ╟─0a77263c-b2fd-4d72-8f73-013294674c53
# ╟─22ef03e5-0e90-466d-9718-a104002b280f
# ╠═014de4bd-c010-47df-a905-744a5f7a680f
# ╟─a3bf38ea-55aa-4c38-9878-50c98d7bcab3
# ╠═48233970-dd55-4ee4-884c-dfaf641ff32c
# ╠═05b03cef-3e2f-4ed2-b413-28cdde115a73
# ╟─8e2250d8-440b-4e86-87ca-936484e9547e
# ╠═1ffb9ee7-8962-4020-a483-7f0e51736f4f
# ╠═f92b1e50-c942-423d-8bcf-4c37de2778bb
# ╠═b0cac714-4eb8-43f2-9537-3b39a51507ca
# ╟─202b5a3c-404c-4cbd-9d13-038cca3013a2
# ╠═c4f810a3-b381-4b53-a1d5-2998bab98655
# ╟─da6e7095-75bc-4100-a634-de6d2d1c7fb7
# ╠═0540ee72-3f67-4e81-a1ec-b5023e08f42b
# ╟─a38c12ec-1e07-4739-88f7-1d9c02513265
# ╠═044ceec2-1cd9-4b8a-a4dd-dcc9cc96ac9b
# ╠═d8566a72-a534-4fd5-ba95-93009e3af312
# ╠═5b0c2b43-9867-4d56-b46f-76c204f6bd49
# ╟─a480ba1b-809f-4760-9eca-f0bba74d2b4b
# ╠═d635ed12-2835-4acd-9589-f7b56a7f54da
# ╠═b7c65265-e9cc-4a3c-9abb-c1249dd25a38
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002