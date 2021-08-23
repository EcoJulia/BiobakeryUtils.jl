using DataFrames
using Random
using Test
using Microbiome
using RCall
using BiobakeryUtils
using SparseArrays
using DelimitedFiles
using CSV

@testset "Metaphlan" begin
    profile_1 = metaphlan_profile("files/metaphlan_single1.tsv")
    @test profile_1["Bacteria", "metaphlan_single1"] == 100.0
    @test profile_1["Coriobacteriia", "metaphlan_single1"] == 0.24757
    @test size(profile_1) == (96, 1)
    profile_2 = metaphlan_profile("files/metaphlan_single1.tsv", 3)
    @test size(profile_2) == (9, 1)
    @test profile_2["Actinobacteria", "metaphlan_single1"] == 10.84221
    profile_3 = metaphlan_profile("files/metaphlan_single1.tsv", :phylum)
    @test size(profile_3) == (4, 1)
    @test profile_3["Bacteroidetes", "metaphlan_single1"] == 25.60381
    
    taxstring = "k__Archaea|p__Euryarchaeota|c__Methanobacteria|o__Methanobacteriales|f__Methanobacteriaceae|g__Methanobrevibacter|s__Methanobrevibacter_smithii"
    taxa = parsetaxa(taxstring)
    @test length(taxa) == 7
    @test parsetaxon(taxstring, 1) == Taxon("Archaea", :kingdom)
    @test parsetaxon(taxstring, :family) == Taxon("Methanobacteriaceae", :family)
    @test parsetaxon(taxstring) == Taxon("Methanobrevibacter_smithii", :species)
    @test_throws ArgumentError parsetaxon(taxstring, 8)

    @test parsetaxon("k__Archaea|p__Euryarchaeota|c__Methanobacteria", 2) == Taxon("Euryarchaeota", :phylum)
    @test parsetaxon("k__Archaea|p__Euryarchaeota|c__Methanobacteria") == Taxon("Methanobacteria", :class)

    taxstring = "k__Archaea|p__Euryarchaeota|c__Methanobacteria|o__Methanobacteriales|f__Methanobacteriaceae|g__Methanobrevibacter|s__Methanobrevibacter_smithii|t__Methanobrevibacter_smithii_unclassified"
    @test findclade(taxstring) == Taxon("Methanobrevibacter_smithii_unclassified", :subspecies)
    @test findclade(taxstring, 4) == Taxon("Methanobacteriales", :order)
    @test findclade(taxstring, :genus) == Taxon("Methanobrevibacter", :genus)
end

@testset "CommunityProfile Testing" begin
    table = CSV.read("files/metaphlan_multi_test.tsv", DataFrame, delim='\t',
    header=["#SampleID", "sample1_taxonomic_profile", "sample2_taxonomic_profile", "sample3_taxonomic_profile",	"sample4_taxonomic_profile", "sample5_taxonomic_profile", "sample6_taxonomic_profile", "sample7_taxonomic_profile"], datarow = 8)
    rename!(table, "#SampleID" => "taxname")
    mat = Matrix(select(table, Not("taxname")))
    tax = Taxon.(table.taxname)
    mss = MicrobiomeSample.(names(table)[2:end])
    cp = CommunityProfile(sparse(mat), tax, mss) # sparse turns matrix into sparse matrix
    
    # @test metaphlan_profiles("metaphlan_multi_test.tsv") <: CommunityProfile
    @test size(cp) == (36,7)
    @test cp[tax[5], mss[5]] == 0.0
    #@test cp[:,[mss[1], mss[4]] ==
    #@test comm[Taxon(tax[1], :kingdom),  sample4_taxonomic_profile] ==
end

@testset "Data Import" begin
    abund = import_abundance_table("files/metaphlan_multi_test.tsv")
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


