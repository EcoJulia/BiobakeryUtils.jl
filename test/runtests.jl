using DataFrames
using Random
using Test
using Microbiome
using RCall
using BiobakeryUtils
using SparseArrays
using DelimitedFiles
using CSV

@testset "CommunityProfile Testing" begin
    table = CSV.read("metaphlan_test.tsv", DataFrame, delim='\t',
    header=["#SampleID", "sample1_taxonomic_profile", "sample2_taxonomic_profile", "sample3_taxonomic_profile",	"sample4_taxonomic_profile", "sample5_taxonomic_profile", "sample6_taxonomic_profile", "sample7_taxonomic_profile"], datarow = 8)
    rename!(table, "#SampleID" => "taxname")
    mat = Matrix(select(table, Not("taxname")))
    tax = Taxon.(table.taxname)
    mss = MicrobiomeSample.(names(table)[2:end])
    cp = CommunityProfile(sparse(mat), tax, mss) # sparse turns matrix into sparse matrix
    @test typeof(cp) <: CommunityProfile
    @test size(cp) == (36,7)
    @test cp[tax[5], mss[5]] == 0.0
    #@test cp[:,[mss[1], mss[4]] ==
    #@test comm[Taxon(tax[1], :kingdom),  sample4_taxonomic_profile] ==
end

@testset "Data Import" begin
    abund = import_abundance_table("metaphlan_test.tsv")
    @test typeof(abund) <: DataFrame
    @test size(abund) == (42, 8)
    spec = taxfilter(abund, keepunidentified=true)
    @test size(spec) == (15, 8)
    phyl = taxfilter(abund, :phylum)
    @test size(phyl) == (2, 8)
    @test !any(occursin.("|", phyl[!, 1]))
    taxfilter!(abund, 2)
    @test abund == phyl

end

# @testset "Permanova" begin
#     reval("install.packages('vegan')")
#     d = rand(10, 10)
#     dm = d + d'
#     p = permanova(dm, repeat(["a", "b"], 5))
#     @test typeof(p) == DataFrame
#     @test size(p) == (3, 6)
# end


