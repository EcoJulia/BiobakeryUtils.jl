function add_metadata!(comm, df, colname)
    for (i, val) in df.colname
        set!(vec_of_mss[i], colname, val)
    end
end


# table = CSV.read("test/metadata.csv", DataFrame, delim='\t',
#     header=["SampleID", "Age(Years)", "Gender",	"Collection Date"], datarow = 1)


# for (i, val) in eachcol(table)
#     println(i) 
#     println(val)
# end

# table = CSV.read("test/metaphlan_test.tsv", DataFrame, delim='\t',
# header=["#SampleID", "sample1_taxonomic_profile", "sample2_taxonomic_profile", "sample3_taxonomic_profile",	"sample4_taxonomic_profile", "sample5_taxonomic_profile", "sample6_taxonomic_profile", "sample7_taxonomic_profile"], datarow = 8)
# rename!(table, "#SampleID" => "taxname")
# mat = Matrix(select(table, Not("taxname")))
# tax = Taxon.(table.taxname)
# # tax = parsetaxon.(table.taxname, throw_error=true)
# # tax = parsetaxon(table.taxname, throw_error=true) = last(parsetaxa(table.taxname, throw_error=true))
# mss = MicrobiomeSample.(names(table)[2:end])
# cp = CommunityProfile(sparse(mat), tax, mss)


for row in CSV.File("test/metadata.csv")
    table = CSV.read("test/metaphlan_test.tsv", DataFrame, delim='\t',
    header=["#SampleID", "sample1_taxonomic_profile", "sample2_taxonomic_profile", "sample3_taxonomic_profile",	"sample4_taxonomic_profile", "sample5_taxonomic_profile", "sample6_taxonomic_profile", "sample7_taxonomic_profile"], datarow = 8)
    rename!(table, "#SampleID" => "taxname")
    mss = MicrobiomeSample.(names(table)[2:end])
    for i in 1:length(row)
        println(set!(mss[i], :row, row[i:i+3]))
    end
end


function add_metadata!(comm, df, colname)
    for row in CSV.File()
        
    end
end


samples(comm[:,"sample1"])
