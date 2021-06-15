using DataFrames
using Random
using Test
using Microbiome
using RCall

reval("install.packages('vegan')")

@testset "Biobakery Utilities" begin
    abund = import_abundance_table("metaphlan_test.tsv")

    @test typeof(abund) <: DataFrame
    @test size(abund) == (42, 8)
    spec = taxfilter(abund, keepunidentified=false)
    @test size(spec) == (15, 8)
    phyl = taxfilter(abund, :phylum)
    @test size(phyl) == (2, 8)

    @test !any(occursin.("|", phyl[!, 1]))

    taxfilter!(abund, 2)
    @test abund == phyl

    d = rand(10, 10)
    dm = d + d'
    p = permanova(dm, repeat(["a", "b"], 5))
    @test typeof(p) == DataFrame
    @test size(p) == (3, 6)
end