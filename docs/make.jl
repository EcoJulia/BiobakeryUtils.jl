using Documenter, BiobakeryUtils

makedocs(
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "BiobakeryUtils.jl",
    pages = [
        "BiobakeryUtils" => "index.md"
        "General Utilities" => "general.md"
        "Working with HUMAnN2" => "humann2.md"
        "Working with MetaPhlAn2" => "metaphlan2.md"
        "Contributing" => "contributing.md"
        "Licence" => "license.md"
    ],
    authors = "Kevin Bonham, PhD"
)

deploydocs(
    repo = "github.com/BioJulia/BiobakeryUtils.jl.git",
    push_preview=true
)
