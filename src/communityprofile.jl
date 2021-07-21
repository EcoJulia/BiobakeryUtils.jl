function add_metadata!(comm, file, colname) #how to get the names of the columns in a csv file? keys(row)
    for row in CSV.File(file)
        for ms in samples(comm)    
            if row[1] == colname # check for sample match
                for i in 1:length(row)
                    set!(ms, :colname, row[i])
                end
            end
        end
    end
end

#add_metadata!(cp, "test/files/metadata_test.csv", )



