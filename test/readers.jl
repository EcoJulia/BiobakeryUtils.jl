@testset "PCL metadata round-trip" begin
    mktempdir() do dir
        profile = CommunityProfile(
            sparse([1.0 0.0; 0.5 2.0; 0.0 0.0]),
            [GeneFunction("A"), GeneFunction("B", Taxon("Bug", :species)), GeneFunction("ZERO")],
            [MicrobiomeSample("s1"; group = "ROC", subject = "one"), MicrobiomeSample("s2"; group = "OOM", subject = "two")]
        )
        path = joinpath(dir, "profile.pcl")
        write_pcl(path, profile; usemetadata = [:group, :subject])
        for last_metadata in (3, "subject")
            restored = read_pcl(path; last_metadata)
            @test samplenames(restored) == samplenames(profile)
            @test features(restored) == features(profile)
            @test abundances(restored) == abundances(profile)
            @test get(restored) == get(profile)
        end

        write_pcl(path, profile; usemetadata = [:group])
        restored = read_pcl(path)
        @test abundances(restored) == abundances(profile)
        @test get(restored, :group) == get(profile, :group)
    end
end

_reader_bytes(text, ::Val{:plain}) = Vector{UInt8}(text)
_reader_bytes(text, ::Val{:gz}) = BiobakeryUtils.transcode(BiobakeryUtils.GzipCompressor, text)
_reader_bytes(text, ::Val{:xz}) = BiobakeryUtils.transcode(BiobakeryUtils.XzCompressor, text)

@testset "Raw tables and direct multi-file assembly" begin
    mktempdir() do dir
        meta1 = "#mpa_database\n#command\n#extra\n#clade_name\tcoverage\tclade_taxid\trelative_abundance\testimated_number_of_reads_from_the_clade\nk__Bacteria\t4\t2\t100\t40\nk__Bacteria|s__Alpha\t4\t2|3\t10\t10\nUNCLASSIFIED\t0\t0\t7\t0\n"
        meta2 = "#mpa_database\n#clade_name\tcoverage\tclade_taxid\trelative_abundance\testimated_number_of_reads_from_the_clade\nk__Bacteria|s__Beta\t4\t2|4\t20\t40\nUNCLASSIFIED\t0\t0\t2\t0\n"
        human1 = "# Gene Family HUMAnN v4.0.0.alpha.1\tsample\nUNMAPPED\t1\nA\t2\nA|s__Bug\t0.5\nZERO\t0\n"
        human2 = "# Gene Family\tsample\nB\t3\nA\t4\nUNMAPPED\t2\n"
        meta_paths, human_paths = String[], String[]
        for (i, (suffix, codec)) in enumerate(((".tsv", :plain), (".tsv.gz", :gz), (".tsv.xz", :xz)))
            mp = joinpath(dir, "tax$i" * suffix)
            hp = joinpath(dir, "gene$i" * suffix)
            write(mp, _reader_bytes(meta1, Val(codec)))
            write(hp, _reader_bytes(human1, Val(codec)))
            push!(meta_paths, mp)
            push!(human_paths, hp)
            raw_meta = read_metaphlan(mp)
            raw_human = read_humann(hp)
            @test BiobakeryUtils.Tables.istable(typeof(raw_meta))
            @test raw_meta.feature == ["k__Bacteria", "k__Bacteria|s__Alpha", "UNCLASSIFIED"]
            @test raw_meta.abundance == [100, 10, 7]
            @test raw_human.feature == ["UNMAPPED", "A", "A|s__Bug", "ZERO"]
            @test raw_human.abundance == [1, 2, 0.5, 0]
            @test samplenames(metaphlan_profile(mp)) == ["tax$i"]
            @test samplenames(humann_profile(hp)) == ["gene$i"]
        end
        @test eltype(abundances(metaphlan_profile(first(meta_paths)))) == Int64
        @test metaphlan_profiles(meta_paths) == commjoin(metaphlan_profile.(meta_paths)...)
        @test humann_profiles(human_paths) == commjoin(humann_profile.(human_paths)...)
        @test humann_profiles(view(human_paths, [3, 1])) == commjoin(humann_profile.(human_paths[[3, 1]])...)
        @test metaphlan_profiles(view(meta_paths, [3, 1]), :species) == commjoin([metaphlan_profile(path, :species) for path in meta_paths[[3, 1]]]...)
        @test eltype(abundances(metaphlan_profiles(meta_paths))) == Float64
        for stratified in (false, true)
            @test humann_profiles(human_paths; stratified) == commjoin([humann_profile(path; stratified) for path in human_paths]...)
        end

        changed_meta = joinpath(dir, "different.tsv")
        changed_human = joinpath(dir, "different_human.tsv")
        write(changed_meta, meta2)
        write(changed_human, human2)
        selected = metaphlan_profiles([first(meta_paths), changed_meta], :species)
        @test features(selected) == [Taxon("Alpha", :species), Taxon("UNCLASSIFIED"), Taxon("Beta", :species)]
        @test Matrix(abundances(selected)) == [10 0; 7 2; 0 20]
        @test humann_profiles([first(human_paths), changed_human]) == commjoin(humann_profile(first(human_paths)), humann_profile(changed_human))
        @test String.(features(humann_profiles([first(human_paths), changed_human]))) == ["UNMAPPED", "A", "ZERO", "B"]

        metadata = [MicrobiomeSample("one"; group = "ROC"), MicrobiomeSample("two"; group = "OOM")]
        joined = humann_profiles([first(human_paths), changed_human]; samples = metadata)
        @test samplenames(joined) == ["one", "two"]
        @test get(samples(joined)[1]) === get(metadata[1])
        @test get(samples(joined)[2]) === get(metadata[2])
        @test_throws ArgumentError humann_profiles(human_paths; samples = ["one"])
        @test_throws ArgumentError metaphlan_profiles(meta_paths; samples = ["one"])
        @test_throws ArgumentError humann_profiles([first(human_paths), first(human_paths)])
        @test_throws ArgumentError metaphlan_profiles(String[])
        @test_throws ArgumentError humann_profiles(String[])
        @test humann_profiles([first(human_paths)]) == humann_profile(first(human_paths))

        meta_io, human_io = IOBuffer(meta1), IOBuffer(human1)
        @test read_metaphlan(meta_io) == read_metaphlan(first(meta_paths))
        @test read_humann(human_io) == read_humann(first(human_paths))
        @test isopen(meta_io) && isopen(human_io)

        legacy = joinpath(dir, "legacy.tsv")
        write(legacy, "ID\tsample\ns__Alpha\t12\n")
        @test metaphlan_profile(legacy)[1, 1] == 12
        empty = joinpath(dir, "empty.tsv")
        write(empty, "# Gene Family\tsample\n")
        @test size(humann_profile(empty)) == (0, 1)
        @test size(humann_profiles([empty])) == (0, 1)
        write(empty, "#clade_name\trelative_abundance\n")
        @test size(metaphlan_profile(empty)) == (0, 1)

        merged = "clade_name\ts1\ts2\nUNCLASSIFIED\t3\t4\nk__Bacteria\t100\t100\nk__Bacteria|s__Alpha\t20\t30\n"
        for (suffix, codec) in ((".tsv", :plain), (".tsv.gz", :gz), (".tsv.xz", :xz))
            path = joinpath(dir, "merged_meta" * suffix)
            write(path, _reader_bytes(merged, Val(codec)))
            @test size(metaphlan_profiles(path, :species)) == (1, 2)
            @test Matrix(abundances(metaphlan_profiles(path, :species; keepunidentified = true))) == [3 4; 20 30]
        end
        path = joinpath(dir, "merged_meta.tsv")
        reference = metaphlan_profiles(path)
        csvpath = joinpath(dir, "roundtrip.csv")
        CSV.write(csvpath, reference)
        @test metaphlan_profiles(csvpath) == reference
    end
end

@testset "Merged HUMAnN sparse construction" begin
    mktempdir() do dir
        text = "# Gene Family\ts1\ts2\nZERO\t0\t\nA\t2\t3\nA|s__Bug\t1\t0.5\n"
        for (suffix, codec) in ((".tsv", :plain), (".tsv.gz", :gz), (".tsv.xz", :xz))
            path = joinpath(dir, "merged" * suffix)
            write(path, _reader_bytes(text, Val(codec)))
            profile = humann_profiles(path)
            @test String.(features(profile)) == ["ZERO", "A"]
            @test Matrix(abundances(profile)) == [0 0; 2 3]
            @test eltype(abundances(profile)) == Float64
            @test nnz(abundances(profile)) == 2
            @test size(humann_profiles(path; stratified = true)) == (3, 2)
            md = [MicrobiomeSample("first"; age = 1), MicrobiomeSample("second"; age = 2)]
            @test get(first(samples(humann_profiles(path; samples = md)))) === get(first(md))
            @test_throws ArgumentError humann_profiles(path; samples = ["short"])
        end
        empty = joinpath(dir, "empty.tsv")
        write(empty, "# Gene Family\ts1\ts2\n")
        @test size(humann_profiles(empty)) == (0, 2)
        @test eltype(features(humann_profiles(empty))) == GeneFunction
        duplicate = joinpath(dir, "duplicate.tsv")
        write(duplicate, "# Gene Family\tsample\nA\t1\nA\t2\n")
        @test_throws ArgumentError humann_profiles([duplicate])
    end
end

@testset "Multi-file loaders match fixture profile joins" begin
    root = joinpath(@__DIR__, "files")
    paths = filter(path -> endswith(path, "_profile.tsv"), readdir(joinpath(root, "metaphlan"); join = true))
    for rank in (:all, :phylum, :class, :species)
        @test metaphlan_profiles(paths, rank) == commjoin([metaphlan_profile(path, rank) for path in paths]...)
    end
    for stratified in (false, true)
        paths = [joinpath(root, "humann", "single_$i.tsv") for i in 1:2]
        @test humann_profiles(paths; stratified) == commjoin([humann_profile(path; stratified) for path in paths]...)
    end
end
