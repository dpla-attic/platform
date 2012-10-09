require 'tire'
require 'v1/repository'

module V1

  module Item
    # Specific fields that can be searched directly
    SEARCHABLE_FIELDS = %w( title description ).freeze

    # Any request outside this list will raise an error
    VALID_FIELDS = (%w( q ) + SEARCHABLE_FIELDS).freeze

    def self.search(params={})
      search = Tire::Search::Search.new(V1::Config::SEARCH_INDEX)

      # free-text search
      if present?(params['q'])
        search.query { |query| query.string(params['q']) }
      end

      #TODO: queries on free-text AND specific queries: not implemented
      #TODO: queries on multiple specific fields: not implemented
      # If the user queried on a specific field that is allowed:
      specific_field = (SEARCHABLE_FIELDS & params.keys).first
      if !specific_field.nil?
        search.query { |query| query.string("#{specific_field}:#{params[specific_field]}") }
      end

      Rails.logger.debug "CURL: #{search.to_curl}"
      Rails.logger.debug search.results.inspect

      search.results
    end

    def self.fetch(id)
      V1::Repository.fetch(id)
    end

    def self.present?(string)
      # copy of the matching Rails ActiveSupport method
      !(string.nil? || string.empty?)
    end

  end

end
