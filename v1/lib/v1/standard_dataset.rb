require 'v1/config'

module V1

  module StandardDataset

    def self.recreate_index!
      # Delete and create the index
      #TODO: add production env check

      items = process_input_file("../standard_dataset/item.json")

      Tire.index(V1::Config::SEARCH_INDEX) do
        delete

        # TODO: move to ES's config/default-mapping.json 
        create :mappings => {
          :item => {
            :properties => {
              #NOTE: No longer needed now that the source data uses _id, I think. -phunk
              :id       => { :type => 'string' },  
              :title    => { :type => 'string' },
              :dplaContributor    => { :type => 'string' },
              :collection    => { :type => 'string' },
              :creator    => { :type => 'string' },
              :publisher   => { :type => 'string' },
              :created => { :type => 'date' },
              :type    => { :type => 'string' }, #image, text, etc
              :format    => { :type => 'string' }, #mime-type
              :language    => { :type => 'string' }, 
              :subject    => { :type => 'string' },
              :description    => { :type => 'string' },
              :rights    => { :type => 'string' },
              :spatial   => { :type => 'string' },
              :temporal    => { :type => 'string' },
              :relation    => { :type => 'string' },
              :source    => { :type => 'string' },
              :contributor    => { :type => 'string' },
              :sourceRecord    => { :type => 'string' }
            }
          }
        }

        import items
        refresh
      end
    end

    def self.process_input_file(json_file)
      # load and pre-process items from the json file
      items_file = File.expand_path(json_file, __FILE__)
      items = JSON.load( File.read(items_file) )
      items.each {|item| item['_type'] = "item"}
    end

  end

end
