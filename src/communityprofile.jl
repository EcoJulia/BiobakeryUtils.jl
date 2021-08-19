function add_metadata!(comm, file) 
    return commjoin(metaphlan_profile(file), comm)
end