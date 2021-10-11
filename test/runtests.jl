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

        profiles = filter(f-> contains(f, "_profile.tsv"), readdir("files/metaphlan", join=true))
        @test metaphlan_merge(profiles, "files/metaphlan/merged_abundance_table.tsv").exitcode == 0
    end

    @testset "Humann" begin
        @test run(`humann --help`).exitcode == 0
    end
end

@testset "Metaphlan" begin
    profile_1 = metaphlan_profile("files/metaphlan/SRS014464-Anterior_nares_profile.tsv";  sample="SRS014464")
    @test first(abundances(profile_1["Bacteria", "SRS014464"])) == 100.0
    @test first(abundances(profile_1["Pseudomonadales", "SRS014464"])) == 97.28734
    @test size(profile_1) == (13, 1)
    profile_2 = metaphlan_profile("files/metaphlan/SRS014459-Stool_profile.tsv", 3)
    @test size(profile_2) == (2, 1)
    @test first(abundances(profile_2["Firmicutes", "SRS014459-Stool_profile"])) == 68.90167
    profile_3 = metaphlan_profile("files/metaphlan/SRS014464-Anterior_nares_profile.tsv", :phylum)
    @test size(profile_3) == (2, 1)
    @test first(abundances(profile_3["Proteobacteria", 1])) == 97.28734
    
    merge_profile_1 = metaphlan_profiles("files/metaphlan/merged_abundance_table.tsv"; samplestart=3)
    @test size(merge_profile_1) == (62, 6)
    @test first(abundances(merge_profile_1["Moraxella", 5])) == 97.28734
    merge_profile_2 = metaphlan_profiles("files/metaphlan/merged_abundance_table.tsv", :family; samplestart=3) 
    @test size(merge_profile_2) == (13, 6)
    @test first(abundances(merge_profile_2["Micrococcaceae", "SRS014464-Anterior_nares"])) == 0.0
    merge_profile_3 = metaphlan_profiles("files/metaphlan/merged_abundance_table.tsv", 7; samplestart=3)
    @test size(merge_profile_3) == (16, 6)
    @test first(abundances(merge_profile_3["Haemophilus_haemolyticus", 3])) == 1.35528
    CSV.write("files/metaphlan/merged_abundance_table2.csv", merge_profile_1)
    
    profiles = filter(f-> contains(f, "_profile.tsv"), readdir("files/metaphlan", join=true))
    @test_throws ArgumentError metaphlan_profiles(profiles; samples = ["sample1"])
    multi_profile_1 = metaphlan_profiles(profiles; samples=["sample$i" for i in 1:length(profiles)])
    @test abundances(multi_profile_1) == abundances(metaphlan_profiles(profiles))
    @test size(multi_profile_1) == (62, 6)
    @test first(abundances(multi_profile_1["Firmicutes", "sample1"])) == 68.90167	
    multi_profile_2 = metaphlan_profiles(profiles, 3; samples=["sample$i" for i in 1:length(profiles)])
    @test abundances(multi_profile_2) == abundances(metaphlan_profiles(profiles, :class))
    @test size(multi_profile_2) == (6,6)
    @test first(abundances(multi_profile_2["Bacteroidia", "sample1"])) == 31.09833	

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
    @test samplenames(p1) == ["single_1"]
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
end

