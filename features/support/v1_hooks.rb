# V1 additions

# Load the standard dataset into ElasticSearch once for all tests
#TODO: tag tests so the repo versus or the search index are selectively set up
# that should also eliminate the potential for river changes sporadically kicking up
# the occasional false negative

V1::StandardDataset.recreate_index!
V1::Repository.recreate_env!



