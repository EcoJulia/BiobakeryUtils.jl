using BiobakeryUtils
using Test

@testset "Biobakery Utilities" begin
     abund = import_abundance("metaphlan_test.tsv")

    @test typeof(abund) <: ComMatrix
    @test size(abund) == (15, 7)
    spec_long = taxfilter(abund, shortnames=false)
    gen_short = taxfilter(abund, level=:phylum)

    @test all(occursin.("|", featurenames(spec_long)))
    @test !any(occursin.("|", featurenames(gen_short)))

    taxfilter!(abund, level=6)
    @test abund == gen_short
end
