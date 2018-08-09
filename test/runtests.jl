using Microbiome
using Test

@testset "Biobakery Utilities" begin
    abund = metaphlan_import("metaphlan_test.tsv", level=:species, shortnames=true)

    @test typeof(abund) <: ComMatrix
    @test size(abund) == (15, 7)
end
