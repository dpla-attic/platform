require_relative '../../app/models/v1/api_key'
require_relative 'repository'

module V1

  module ApiAuth

    def self.auth_database
      Repository.admin_cluster_auth_database
    end

    def self.create_api_key(owner)
      key = ApiKey.new('db' => auth_database, 'owner' => owner)
      key.save
      key
    end

    def self.find_api_key_by_owner(owner)
      key = ApiKey.find_by_owner(auth_database, owner)
      key ? key['_id'] : nil
    end

    def self.find_api_key_by_key(key_id)
      ApiKey.find_by_key(auth_database, key_id)
    end
   
    def self.authenticate_api_key(key_id)
      ApiKey.authenticate(auth_database, key_id)
    end

    def self.clear_cached_auth(key_id)
      ApiKey.clear_cached_auth(key_id)
    end

    def self.show_api_auth(key_id)
      #TODO: move most of this to the ApiKey model
      if key_id.respond_to?(:disabled?)
        key_id
      elsif ApiKey.looks_like_key(key_id)
        ApiKey.find_by_key(auth_database, key_id)
      elsif ApiKey.looks_like_owner(key_id)
        ApiKey.find_by_owner(auth_database, key_id)
      else
        "Key '#{key_id}' does not look like a key or an owner, so I don't know what to tell you"
      end
    end

    def self.toggle_api_auth(key_id)
      key = ApiKey.find_by_key(auth_database, key_id)
      raise "API key not found: #{key_id}" unless key

      key.toggle_disabled
      clear_cached_auth(key_id)
      key
    end

  end

end

