require 'cucumber/rspec/doubles'

# API additions

Before do
  @params = {}
  # These keys will only exist in the test environment
  @valid_api_key = 'aa11d0958e93bb25e457a726dc10a40f'
  @disabled_api_key = 'dd11db4564399e6dc1cf26456f29f1b6'
  # this one is the correct format, but does not exist
  @invalid_api_key = '6c30d962ed96c45c7f007635ef011354'
end

Before("@api_key_generation") do
  puts 'Before("@api_key_generation") do'
end

After("@api_key_generation") do
  puts 'After("@api_key_generation") do'
end

if ENV['CUKE_SETUP'] == 'skip'
  puts "~~~~~~~~~~~~~~~~\n~~~~~~~~~~~~ SKIPPING Setup Yo. ~~~~~~~~~~~~"
  puts                   "~~~~~~~ (ENV['CUKE_SETUP'] == 'skip' ~~~~~~~"
  puts "~~~~~~~~~~~~~~~~"
else
  # Load the standard dataset into CouchDB and let the river get that data into ElasticSearch
  # Ultimately, this should be split up into smaller elasticsearch, couch and river test sets
  # and tags would be used to create the correct datasets. That would also eliminate the
  # possibility of pagination causing false negatives between test runs on different systems.

  V1::StandardDataset.recreate_index!
  V1::Repository.recreate_env(true)

  # Sleep a bit to let CouchDB finish doing its thing internally, as well as letting 
  # the river catch up on indexing the docs added to CouchDB.
  # Note: A HTTP 419 error from CouchDB means you need to increase that sleep value
  # a second or two.
  sleep 5
  puts "Search docs       : #{V1::StandardDataset.doc_count}"
end


