module Contentqa
  module SearchHelper

    def display_record (record)
      "This is arecord"
    end

    def dotted_hash_value(hash, key)
      # Used to access a search result doc via a field name. E.g. sourceResource.date.begin
      # Note: Does not work if the "date" field in sourceResource.date.begin is an array of hashes.
      key.split('.').inject(hash) do |h, key|
        h[key] rescue nil
      end
    end

  end
end
