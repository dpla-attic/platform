# V1 additions

# Load the standard dataset into CouchDB and let the river get that data into ElasticSearch
# Ultimately, this should be split up into smaller elasticsearch, couch and river test sets
# and tags would be used to create the correct datasets. That would also eliminate the
# possibility of pagination causing false negatives between test runs on different systems.

# puts "~~~~~~~~~~~~~~~~\n~~~~~~~~~~~~ SKIPPING Setup Yo. ~~~~~~~~~~~~\n~~~~~~~~~~~~~~~~"
V1::StandardDataset.recreate_index!
V1::Repository.recreate_env!



