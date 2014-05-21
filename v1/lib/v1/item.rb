require_relative 'searchable'

module V1

  module Item
    extend Searchable
    
    def self.resource
      'item'
    end

  end

end
