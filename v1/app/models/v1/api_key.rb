require 'securerandom'
require 'restclient/exceptions'

module V1

  class ApiKey 

    # Valid keys are 32 character hex strings
    VALID_KEY_REGEX = /^[0-9a-f]{32}$/
    
    attr_reader :db, :owner, :id, :disabled
    
    def initialize(args={})
      #TODO: raise api specific exception if email looks invalid or missing
      @db = args['db']
      raise ArgumentError, "Missing 'db' param" if @db.nil?

      @owner = self.class.sanitize_email(args['owner'])
      @id = build_key      
      @disabled = args['disabled']
    end
    
    def disable
      @disabled = true
    end

    def enable
      @disabled = false
    end

    def save
      db.save_doc(self.to_hash)
    end

    def to_hash
      h = {
        '_id' => id,
        'owner' => owner,
      }
      h['disabled'] = true if disabled
      h
    end

    def self.find_by_key(db, key_id)
      begin
        #TODO: THIS should return an instance of ApiKey
        db.get(key_id)
      rescue RestClient::ResourceNotFound
        nil
      end
    end

    def self.find_by_owner(db, owner)
      owner = self.sanitize_email(owner)
      key = db.view('api_auth_utils/find_by_owner', 'key' => owner)['rows'].first
      key ? key['value'] : nil
    end

    def self.authenticate(db, key_id)
      # Returns the boolean of "is this key valid and authenticated"
      return false unless key_id =~ VALID_KEY_REGEX
      
      # Let Errno::ECONNREFUSED exceptions bubble up here
      key = self.find_by_key(db, key_id)
      return false if key.nil?

      !(key['disabled'] === true)
    end

    def build_key
      SecureRandom.hex(16)
    end

    def self.sanitize_email(email)
      raise ArgumentError, "Missing 'owner' param" if email.to_s == ''
      
      email.downcase!

      # Always remove periods from Gmail usernames because Gmail ignores them
      if email =~ /^(.+)(@gmail\.com)$/
        email = $1.gsub('.', '') + '@gmail.com'
      end
      email      
    end

  end

end
