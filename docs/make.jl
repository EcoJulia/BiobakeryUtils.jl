using Documenter, BiobakeryUtils

makedocs(
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "BiobakeryUtils.jl",
    pages = [
        "BiobakeryUtils" => "index.md",
        "Getting Started" => "gettingstarted.md",
        "Working with MetaPhlAn" => "metaphlan.md",
        "Working with HUMAnN" => "humann.md",
        "Microbiome.jl Docstrings" => "microbiome.md",
        "Contributing" => "contributing.md"
    ],
    authors = "Kevin Bonham, PhD"
)

deploydocs(
    repo = "github.com/EcoJulia/BiobakeryUtils.jl.git",
    push_preview=true,
    devbranch="main"
)
