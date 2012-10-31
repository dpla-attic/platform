# V1 additions
require 'v1/standard_dataset'

# Load the standard dataset into ElasticSearch once for all tests
V1::StandardDataset.recreate_index!
