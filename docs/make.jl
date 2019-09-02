using Documenter, BiobakeryUtils

makedocs(
    sitename="BioBakery Utilities"
)

deploydocs(
    repo = "github.com/BioJulia/BiobakeryUtils.jl.git",
    osname="linux",
    deps = nothing,
)
