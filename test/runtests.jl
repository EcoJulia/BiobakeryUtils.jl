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
    
    merge_profile_1 = metaphlan_profiles("files/metaphlan_multi_test.tsv")
    @test size(merge_profile_1) == (42, 7)
    @test merge_profile_1["Actinomycetales", "sample3_taxonomic"] == 0.08487
    merge_profile_2 = metaphlan_profiles("files/metaphlan_multi_test.tsv", :family)
    @test size(merge_profile_2) == (2, 7)
    @test merge_profile_2["Actinomycetaceae", "sample7_taxonomic"] == 0.03716
    merge_profile_3 = metaphlan_profiles("files/metaphlan_multi_test.tsv", 7)
    @test size(merge_profile_3) == (15, 7)
    @test merge_profile_3["Actinomyces_viscosus", "sample2_taxonomic"] == 0.03457

    multi_profile_1 = metaphlan_profiles(["files/metaphlan_single1.tsv", "files/metaphlan_single2.tsv"])
    @test size(multi_profile_1) == (129, 2)
    @test multi_profile_1["Firmicutes", "metaphlan_single1"] == 63.1582	
    @test multi_profile_1["Firmicutes", "metaphlan_single2"] == 48.57123
    multi_profile_2 = metaphlan_profiles(["files/metaphlan_single1.tsv", "files/metaphlan_single2.tsv"], 3)
    @test size(multi_profile_2) == (11, 2)
    @test multi_profile_2["Bacteroidia", "metaphlan_single1"] == 25.60381	
    @test multi_profile_2["Bacteroidia", "metaphlan_single2"] == 47.67359	
    multi_profile_3 = metaphlan_profiles(["files/metaphlan_single1.tsv", "files/metaphlan_single2.tsv"], :order)
    @test size(multi_profile_3) == (13, 2)
    @test multi_profile_3["Bifidobacteriales", "metaphlan_single1"] == 10.84221
    @test multi_profile_3["Bifidobacteriales", "metaphlan_single2"] == 1.46697	


    taxstring = "k__Archaea|p__Euryarchaeota|c__Methanobacteria|o__Methanobacteriales|f__Methanobacteriaceae|g__Methanobrevibacter|s__Methanobrevibacter_smithii"
    taxa = parsetaxa(taxstring)
    @test length(taxa) == 7
    @test parsetaxon(taxstring, 1) == Taxon("Archaea", :kingdom)
    @test parsetaxon(taxstring, :family) == Taxon("Methanobacteriaceae", :family)
    @test parsetaxon(taxstring) == Taxon("Methanobrevibacter_smithii", :species)
    @test_throws ArgumentError parsetaxon(taxstring, 8)

    @test parsetaxon("k__Archaea|p__Euryarchaeota|c__Methanobacteria", 2) == Taxon("Euryarchaeota", :phylum)
    @test parsetaxon("k__Archaea|p__Euryarchaeota|c__Methanobacteria") == Taxon("Methanobacteria", :class)
end

@testset "HUMAnN" begin
    p1 = humann_profile("files/humann_single_1.tsv")
    p2 = humann_profile("files/humann_single_2.tsv")
    @test p1 isa CommunityProfile
    @test size(p1) == (560, 1)
    @test samplenames(p1) == ["humann_single_1"]
    @test samplenames(humann_profile("files/humann_single_1.tsv"; sample = "sample1")) == ["sample1"]
    @test samplenames(humann_profile("files/humann_single_1.tsv"; sample = MicrobiomeSample("sample1"))) == ["sample1"]

    @test all(f-> !hastaxon(f), features(p1)) # unstratified
    @test all(f-> !occursin('|', name(f)), features(p1))

    pj = humann_profiles("files/humann_joined.tsv")
    @test size(pj) == (560, 2)
    @test isempty(setdiff(features(pj), features(commjoin(p1, p2))))
    @test samplenames(pj) == samplenames(commjoin(p1, p2))

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


