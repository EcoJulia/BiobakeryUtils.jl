using Documenter, BiobakeryUtils

makedocs(
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "BiobakeryUtils.jl",
    pages = [
        "BiobakeryUtils" => "index.md",
        "General Utilities" => "general.md",
        "Getting Started" => "gettingstarted.md",
        "Working with HUMAnN" => "humann.md",
        "Working with MetaPhlAn" => "metaphlan.md",
        "Contributing" => "contributing.md"
    ],
    authors = "Kevin Bonham, PhD"
)

deploydocs(
    repo = "github.com/BioJulia/BiobakeryUtils.jl.git",
    push_preview=true,
    devbranch="main"
)
