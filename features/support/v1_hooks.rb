# API additions

do_setup = true

if do_setup
  # Load the standard dataset into CouchDB and let the river get that data into ElasticSearch
  # Ultimately, this should be split up into smaller elasticsearch, couch and river test sets
  # and tags would be used to create the correct datasets. That would also eliminate the
  # possibility of pagination causing false negatives between test runs on different systems.

  V1::StandardDataset.recreate_index!
  V1::Repository.recreate_env!

  # Sleep a bit to let CouchDB finish doing its thing internally, as well as letting 
  # the river catch up on indexing the docs added to CouchDB.
  # Note: A HTTP 419 error from CouchDB means you need to increase that sleep value
  # a second or two, I believe.
  sleep 1
else
  puts "~~~~~~~~~~~~~~~~\n~~~~~~~~~~~~ SKIPPING Setup Yo. ~~~~~~~~~~~~\n~~~~~~~~~~~~~~~~"
end


