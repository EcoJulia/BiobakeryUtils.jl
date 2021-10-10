using Random
using Test
using BiobakeryUtils
using BiobakeryUtils.Conda
using SparseArrays
using DelimitedFiles
using CSV

isdir(Conda.bin_dir(:BiobakeryUtils)) || BiobakeryUtils.install_deps()
ENV["PATH"] = ENV["PATH"] * ":" * Conda.bin_dir(:BiobakeryUtils)

@testset "CLI" begin
    @testset "Metaphlan" begin
        @test run(`metaphlan --help`).exitcode == 0

        profiles = filter(f-> contains(f, "_profile.tsv"), readdir("files/metphlan", join=true))
        metaphlan_merge(profiles, "files/metaphlan/merged_abundance_table.tsv")
end

@testset "Metaphlan" begin
    profile_1 = metaphlan_profile("files/metaphlan/SRS014464-Anterior_nares_profile.tsv", "SRS014464")
    @test profile_1["Bacteria", "SRS014464"] == 100.0
    @test profile_1["Coriobacteriia", "SRS014464"] == 0.24757
    @test size(profile_1) == (96, 1)
    profile_2 = metaphlan_profile("files/metaphlan/SRS014459-Stool_profile.tsv", 3)
    @test size(profile_2) == (9, 1)
    @test profile_2["Actinobacteria", "SRS014464"] == 10.84221
    profile_3 = metaphlan_profile("test/files/metaphlan/SRS014464-Anterior_nares_profile.tsv", :phylum)
    @test size(profile_3) == (4, 1)
    @test profile_3["Bacteroidetes", "SRS014464"] == 25.60381
    
    merge_profile_1 = metaphlan_profiles("files/metaphlan/merged_abundance_tables.tsv")
    @test size(merge_profile_1) == (42, 7)
    @test merge_profile_1["Actinomycetales", "sample3"] == 0.08487
    merge_profile_2 = metaphlan_profiles("files/metaphlan/metaphlan_multi_test.tsv", :family)
    @test size(merge_profile_2) == (2, 7)
    @test merge_profile_2["Actinomycetaceae", "sample7"] == 0.03716
    merge_profile_3 = metaphlan_profiles("files/metaphlan/metaphlan_multi_test.tsv", 7)
    @test size(merge_profile_3) == (15, 7)
    @test merge_profile_3["Actinomyces_viscosus", "sample2"] == 0.03457

    # multi_profile_1 = metaphlan_profiles(["test/files/metaphlan/SRS014464-Anterior_nares_profile.tsv", "files/metaphlan/metaphlan_single2.tsv"])
    # @test size(multi_profile_1) == (129, 2)
    # @test multi_profile_1["Firmicutes", "SRS014464"] == 63.1582	
    # @test multi_profile_1["Firmicutes", "metaphlan_single2"] == 48.57123
    multi_profile_2 = metaphlan_profiles(["test/files/metaphlan/SRS014464-Anterior_nares_profile.tsv", "files/metaphlan/metaphlan_single2.tsv"], 3)
    @test size(multi_profile_2) == (11, 2)
    @test multi_profile_2["Bacteroidia", "SRS014464"] == 25.60381	
    @test multi_profile_2["Bacteroidia", "metaphlan_single2"] == 47.67359	
    multi_profile_3 = metaphlan_profiles(["test/files/metaphlan/SRS014464-Anterior_nares_profile.tsv", "files/metaphlan/metaphlan_single2.tsv"], :order)
    @test size(multi_profile_3) == (13, 2)
    @test multi_profile_3["Bifidobacteriales", "SRS014464"] == 10.84221
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
    p1 = humann_profile("files/humann/single_1.tsv")
    p2 = humann_profile("files/humann/single_2.tsv")
    @test p1 isa CommunityProfile
    @test size(p1) == (560, 1)
    @test samplenames(p1) == ["humann_single_1"]
    @test samplenames(humann_profile("files/humann/single_1.tsv"; sample = "sample1")) == ["sample1"]
    @test samplenames(humann_profile("files/humann/single_1.tsv"; sample = MicrobiomeSample("sample1"))) == ["sample1"]

    @test all(f-> !hastaxon(f), features(p1)) # unstratified
    @test all(f-> !occursin('|', name(f)), features(p1))

    pj = humann_profiles("files/humann/joined.tsv")
    @test size(pj) == (560, 2)
    @test isempty(setdiff(features(pj), features(commjoin(p1, p2))))
    @test samplenames(pj) == samplenames(commjoin(p1, p2))

    pj_strat = humann_profiles("files/humann/joined.tsv"; stratified = true)
    @test size(pj_strat) == (1358, 2)
    @test !isempty(setdiff(features(pj_strat), features(pj)))
    @test isempty(setdiff(featurenames(pj_strat), featurenames(pj)))
    @test isempty(setdiff(features(filter(!hastaxon, pj_strat)), features(pj)))
    CSV.write("files/humann/joined_roundtrip.tsv", pj_strat; delim='\t')
    @test features(pj_strat) == features(humann_profiles("files/humann/joined_roundtrip.tsv"; stratified=true))
end

