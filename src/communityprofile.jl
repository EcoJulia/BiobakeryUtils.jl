function add_metadata!(comm, file) #how to get the names of the columns in a csv file? keys(row)
    for line in CSV.File(file)
        row = first(line)
        for ms in samples(comm)   
            colname = keys(row) 
            if row[1] == colname # check for sample match
                for i in 1:length(row)
                    set!(ms, keys(row), row[i])
                end
            end
        end
    end
end

#add_metadata!(cp, "test/files/metadata_test.csv", )


#= table = CSV.read("test/files/metaphlan_multi_test.tsv", DataFrame, delim='\t',
    header =["#SampleID", "sample1_taxonomic_profile", "sample2_taxonomic_profile", "sample3_taxonomic_profile",	"sample4_taxonomic_profile", "sample5_taxonomic_profile", "sample6_taxonomic_profile", "sample7_taxonomic_profile"], datarow = 8)
    rename!(table, "#SampleID" => "taxname")
    mat = Matrix(select(table, Not("taxname")))
    tax = [parsetaxon.(str) for str in table.taxname]
    mss = MicrobiomeSample.(names(table)[2:end])
    comm = CommunityProfile(sparse(mat), tax , mss)
          
    colnames = keys(first(CSV.File("test/files/metadatam_test.csv")))
    for ms in samples(comm)  
        for elt in colnames
            for item in file
                for i in 1:length(item)
                    #println(set!(ms, elt, item))
                    println(elt)
                    println(item)
                    println(i)
                end
            end
        end
    end

        for ms in samples(comm)  
        if row[1] == colname # check for sample match
            for i in 1:length(row)
                set!(ms, colnames, row[i])
            end
        end
    end
end
 =#