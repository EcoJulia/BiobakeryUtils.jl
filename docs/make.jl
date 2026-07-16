using Documenter, BiobakeryUtils

makedocs(
    sitename = "BiobakeryUtils.jl",
    warnonly = [:missing_docs, :cross_references],
    doctest = false, # doctests depend on Conda setup being removed in 0.8
    pages = [
        "BiobakeryUtils" => "index.md",
        "Getting Started" => "gettingstarted.md",
        "Working with KneadData" => "kneaddata.md",
        "Working with MetaPhlAn" => "metaphlan.md",
        "Working with HUMAnN" => "humann.md",
        "Microbiome.jl Docstrings" => "microbiome.md",
    ],
    authors = "Kevin Bonham, PhD",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        edit_link = "main",
        canonical = "https://docs.ecojulia.org/BiobakeryUtils.jl/stable/",
    ),
)

deploydocs(
    repo = "github.com/EcoJulia/BiobakeryUtils.jl.git",
    push_preview=true,
    devbranch="main"
)
