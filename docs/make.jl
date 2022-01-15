using Documenter, BiobakeryUtils

makedocs(
    sitename = "BiobakeryUtils.jl",
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
        edit_link="main",
        canonical="http://docs.ecojulia.org/BiobakeryUtils.jl/stable/"),
        )

deploydocs(
    repo = "github.com/EcoJulia/BiobakeryUtils.jl.git",
    push_preview=true,
    devbranch="main"
)
