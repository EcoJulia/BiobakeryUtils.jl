using BiobakeryUtils
using DataFrames
using Test

@testset "Biobakery Utilities" begin
     abund = import_abundance("metaphlan_test.tsv")

    @test typeof(abund) <: DataFrame
    @test size(abund) == (42, 8)
    spec_long = taxfilter(abund, shortnames=false)
    @test size(spec_long) == (15, 8)
    phyl_short = taxfilter(abund, :phylum)
    @test size(phyl_short) == (2, 8)

    @test all(occursin.("|", spec_long[1]))
    @test !any(occursin.("|", phyl_short[1]))

    taxfilter!(abund, 2)
    @test abund == phyl_short
end
