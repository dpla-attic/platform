require_relative 'searchable'

module V1

  module Collection
    extend Searchable
    
    def self.resource
      'collection'
    end

  end

end
