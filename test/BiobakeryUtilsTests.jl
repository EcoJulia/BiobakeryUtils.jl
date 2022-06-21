module BiobakeryUtilsTests

using Random
using ReTest
using BiobakeryUtils
using BiobakeryUtils.Conda
using SparseArrays
using DelimitedFiles
using CSV

isdir(Conda.bin_dir(:BiobakeryUtils)) || BiobakeryUtils.install_deps()
ENV["PATH"] = ENV["PATH"] * ":" * Conda.bin_dir(:BiobakeryUtils)

@testset "CLI" begin
    @testset "Utilities" begin
        cmd = ["thing", "foo_bar"]         
        cmd2 = copy(cmd)

        BiobakeryUtils.add_cli_kwargs!(cmd, Dict(:some_thing=> "foo", :bool=> true))
        @test all(cmd .== ["thing", "foo_bar", "--some_thing", "foo", "--bool"])
        BiobakeryUtils.add_cli_kwargs!(cmd2, Dict(:some_thing=> "foo", :bool=> true); optunderscores=false)
        @test all(cmd2 .== ["thing", "foo_bar", "--some-thing", "foo", "--bool"])
    end
    
    @testset "Metaphlan" begin
        @test BiobakeryUtils.check_for_install("metaphlan") |> isnothing
        @test BiobakeryUtils.check_for_install("merge_metaphlan_tables.py") |> isnothing
        
        @test metaphlan("", ""; help=true).exitcode == 0

        profiles = filter(f-> contains(f, "_profile.tsv"), readdir(joinpath(@__DIR__, "files/metaphlan"), join=true))
        @test metaphlan_merge(profiles, joinpath(@__DIR__, "files/metaphlan/merged_abundance_table.tsv")).exitcode == 0
    end

    @testset "Humann" begin
        @test BiobakeryUtils.check_for_install("humann") |> isnothing
        @test BiobakeryUtils.check_for_install("humann_rename_table") |> isnothing
        @test BiobakeryUtils.check_for_install("humann_renorm_table") |> isnothing
        @test BiobakeryUtils.check_for_install("humann_join_tables") |> isnothing
        @test BiobakeryUtils.check_for_install("humann") |> isnothing
        @test humann("", ""; help=true).exitcode == 0

    end
end

@testset "Metaphlan" begin
    profile_1 = metaphlan_profile(joinpath(@__DIR__, "files/metaphlan/SRS014464-Anterior_nares_profile.tsv");  sample="SRS014464")
    @test profile_1["k__Bacteria", "SRS014464"] == 100.0
    @test profile_1["o__Pseudomonadales", "SRS014464"] == 97.28734
    @test size(profile_1) == (13, 1)
    profile_2 = metaphlan_profile(joinpath(@__DIR__, "files/metaphlan/SRS014459-Stool_profile.tsv"), 3)
    @test size(profile_2) == (2, 1)
    @test profile_2["p__Firmicutes", "SRS014459-Stool_profile"] == 68.90167
    profile_3 = metaphlan_profile(joinpath(@__DIR__, "files/metaphlan/SRS014464-Anterior_nares_profile.tsv"), :phylum)
    @test size(profile_3) == (2, 1)
    @test profile_3["p__Proteobacteria", 1] == 97.28734
    
    merge_profile_1 = metaphlan_profiles(joinpath(@__DIR__, "files/metaphlan/merged_abundance_table.tsv"); samplestart=3)
    @test size(merge_profile_1) == (62, 6)
    @test merge_profile_1["g__Moraxella", 5] == 97.28734
    merge_profile_2 = metaphlan_profiles(joinpath(@__DIR__, "files/metaphlan/merged_abundance_table.tsv"), :family; samplestart=3) 
    @test size(merge_profile_2) == (13, 6)
    @test merge_profile_2["f__Micrococcaceae", "SRS014464-Anterior_nares"] == 0.0
    merge_profile_3 = metaphlan_profiles(joinpath(@__DIR__, "files/metaphlan/merged_abundance_table.tsv"), 7; samplestart=3)
    @test size(merge_profile_3) == (16, 6)
    @test merge_profile_3["s__Haemophilus_haemolyticus", 3] == 1.35528
    CSV.write(joinpath(@__DIR__, "files/metaphlan/merged_abundance_table2.csv"), merge_profile_1)
    
    profiles = filter(f-> contains(f, "_profile.tsv"), readdir(joinpath(@__DIR__, "files/met aphlan"), join=true))
    @test_throws ArgumentError metaphlan_profiles(profiles; samples = ["sample1"])
    multi_profile_1 = metaphlan_profiles(profiles; samples=["sample$i" for i in 1:length(profiles)])
    @test abundances(multi_profile_1) == abundances(metaphlan_profiles(profiles))
    @test size(multi_profile_1) == (62, 6)
    @test multi_profile_1["p__Firmicutes", "sample1"] == 68.90167	
    multi_profile_2 = metaphlan_profiles(profiles, 3; samples=["sample$i" for i in 1:length(profiles)])
    @test abundances(multi_profile_2) == abundances(metaphlan_profiles(profiles, :class))
    @test size(multi_profile_2) == (6,6)
    @test multi_profile_2["c__Bacteroidia", "sample1"] == 31.09833	

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
    p1 = humann_profile(joinpath(@__DIR__, "files/humann/single_1.tsv"))
    p2 = humann_profile(joinpath(@__DIR__, "files/humann/single_2.tsv"))
    @test p1 isa CommunityProfile
    @test size(p1) == (560, 1)
    @test samplenames(p1) == ["single_1"]
    @test samplenames(humann_profile(joinpath(@__DIR__, "files/humann/single_1.tsv"); sample = "sample1")) == ["sample1"]
    @test samplenames(humann_profile(joinpath(@__DIR__, "files/humann/single_1.tsv"); sample = MicrobiomeSample("sample1"))) == ["sample1"]

    @test all(f-> !hastaxon(f), features(p1)) # unstratified
    @test all(f-> !occursin('|', name(f)), features(p1))

    pj = humann_profiles(joinpath(@__DIR__, "files/humann/joined.tsv"))
    @test size(pj) == (560, 2)
    @test isempty(setdiff(features(pj), features(commjoin(p1, p2))))
    @test samplenames(pj) == samplenames(commjoin(p1, p2))

    pj_strat = humann_profiles(joinpath(@__DIR__, "files/humann/joined.tsv"); stratified = true)
    @test size(pj_strat) == (1358, 2)
    @test !isempty(setdiff(features(pj_strat), features(pj)))
    @test isempty(setdiff(featurenames(pj_strat), featurenames(pj)))
    @test isempty(setdiff(features(filter(!hastaxon, pj_strat)), features(pj)))
    CSV.write(joinpath(@__DIR__, "files/humann/joined_roundtrip.tsv"), pj_strat; delim='\t')
end

end # module