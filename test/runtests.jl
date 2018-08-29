using BiobakeryUtils
using DataFrames
using Random
using Test

@testset "Biobakery Utilities" begin
    abund = import_abundance_table("metaphlan_test.tsv")

    @test typeof(abund) <: DataFrame
    @test size(abund) == (42, 8)
    spec_long = taxfilter(abund, shortnames=false)
    @test size(spec_long) == (15, 8)
    phyl_short = taxfilter(abund, :phylum)
    @test size(phyl_short) == (2, 8)

    @test all(occursin.("|", spec_long[1]))
    rm_strat!(spec_long)
    @test !any(occursin.("|", spec_long[1]))

    @test !any(occursin.("|", phyl_short[1]))

    taxfilter!(abund, 2)
    @test abund == phyl_short

    @test present(0.1, 0.001)
    @test !present(0.001, 0.1)
    @test present(rand(), 0)

    a = zeros(100)
    a[randperm(100)[1:10]] .= rand(10)

    @test prevalence(a, 0) == 0.1
end
