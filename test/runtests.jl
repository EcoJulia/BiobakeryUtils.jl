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
    @test parsetaxon("k__Archaea|p__Euryarchaeota|c__Methanobacteria", 2) == Taxon("Euryarchaeota", :phylum)
    @test parsetaxon("k__Archaea|p__Euryarchaeota|c__Methanobacteria") == Taxon("Methanobacteria", :class)
end

@testset "Data Import" begin
    abund = import_abundance_table("files/metaphlan_multi_test.tsv")
    abund = import_abundance_tables(["files/metaphlan_single1.tsv","test/files/metaphlan_single2.tsv"])
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

@testset "rm_strat!" begin
    comm = rm_strat!(abund, col=1)
    @test typeof(comm) <: CommunityProfile
end

@testset "add_metadata!" begin
    comm=metaphlan_profile("files/metaphlan_single1.tsv")    
    add_metadata!(comm, "files/metaphlan_single2.tsv")    
    @test typeof(comm) <: CommunityProfile
end

@testset "CommunityProfile Testing" begin
    
#Replace all this with metaphlanprofile
    
    table = CSV.read("files/metaphlan_multi_test.tsv", DataFrame, delim = "\t",
    header =["#SampleID", "sample1_taxonomic_profile", "sample2_taxonomic_profile", "sample3_taxonomic_profile", "sample4_taxonomic_profile", "sample5_taxonomic_profile", "sample6_taxonomic_profile", "sample7_taxonomic_profile"], datarow = 2)
    rename!(table, "#SampleID" => "taxname")
    mat = Matrix(select(table, Not("taxname")))
    tax = [parsetaxon.(str) for str in table.taxname]
    mss = MicrobiomeSample.(names(table)[2:end])
    comm = CommunityProfile(sparse(mat), tax , mss) # sparse turns matrix into sparse matrix
    @test size(comm) == (42,7)
    @test comm[tax[5], mss[5]] == 0.0    
end




# @testset "Permanova" begin
#     reval("install.packages('vegan')")
#     d = rand(10, 10)
#     dm = d + d'
#     p = permanova(dm, repeat(["a", "b"], 5))
#     @test typeof(p) == DataFrame
#     @test size(p) == (3, 6)
# end



# for t in ["test/files/metaphlan_single1.tsv","test/files/metaphlan_single2.tsv"]
#     fulltable = DataFrame(col1=String[])
#     df = import_abundance_table(t, delim='\t')
#     #println(t)
#     #println(df)
#     fulltable = outerjoin(fulltable,df,on=:col1)
#     println("Fulltable")
#     println(fulltable)
# end

# fulltable = map(c -> eltype(c) <: Union{<:Number, Missing} ? collect(Missings.replace(c, 0)) : c, eachcol(fulltable))
# return fulltable

# import_abundance_table("test/files/metaphlan_single1.tsv")
# import_abundance_tables(["test/files/metaphlan_single1.tsv","test/files/metaphlan_single2.tsv"])
# clean_abundance_tables(["test/files/metaphlan_single1.tsv","test/files/metaphlan_single2.tsv"])
