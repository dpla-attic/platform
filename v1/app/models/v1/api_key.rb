require 'securerandom'
require 'restclient/exceptions'

module V1

  class ApiKey 

    attr_reader :db, :owner, :id, :disabled, :_rev, :created_at, :updated_at

    #TODO: manage _id internally using id() and id= methods
    
    def initialize(args={})
      #TODO: raise api specific exception if email looks invalid or missing
      raise ArgumentError, "Missing 'db' param" if args['db'].nil?

      @db = args['db']
      @disabled = args['disabled']

      if args['id']
        # init from args
        @id = args['id']
        @owner = args['owner']
        @_rev = args['_rev']
        @created_at = args['created_at']
        @updated_at = args['updated_at']
      else
        # init as new
        @id = generate_key_id
        @owner = self.class.sanitize_email(args['owner'])
      end
    end
    
    def disable
      @disabled = true
    end

    def enable
      @disabled = false
    end

    def disabled?
      self.disabled
    end

    def toggle_disabled
      self.disabled? ? enable : disable
      save
    end
    
    def save
      timestamp = build_timestamp
      @created_at = created_at || timestamp 
      @updated_at = timestamp
      db.save_doc(self.to_hash)
    end

    def build_timestamp
      Time.now.to_s
    end

    def to_s
      to_hash
    end

    def to_hash
      h = {
        '_id' => id,
        'owner' => owner,
        'created_at' => created_at,
        'updated_at' => updated_at,
      }
      h['disabled'] = true if disabled?
      h['_rev'] = _rev if _rev

      h
    end

    def generate_key_id
      SecureRandom.hex(16)
    end

    def self.cache_key(key_id)
      # cache keys cannot be blank
      key_id.to_s != '' ? key_id.to_s : 'none'
    end

    def self.find_by_key(db, key_id)
      begin
        db_key = db.get(key_id)
        self.new({
                   'db' => db,
                   'id' => db_key['_id'],
                   '_rev' => db_key['_rev'],
                   'owner' => db_key['owner'],
                   'disabled' => !!db_key['disabled'],
                   'created_at' => db_key['created_at'],
                   'updated_at' => db_key['updated_at'],
                 })
      rescue RestClient::ResourceNotFound
        nil
      end
    end

    def self.find_by_owner(db, owner)
      #TODO: return ApiKey instance like find_by_key does
      owner = self.sanitize_email(owner)
      key = db.view('api_auth_utils/find_by_owner', 'key' => owner)['rows'].first
      key ? key['value'] : nil
    end

    def self.looks_like_key(string)
      # Valid keys are 32 character hex strings
      string =~ /^[0-9a-f]{32}$/
    end

    def self.looks_like_owner(string)
      # very loose 'email-ish' test
      string =~ /\w+@\w+\.\w+/
    end

    def self.authenticate(db, key_id)
      # Returns the boolean of "is this key valid and authenticated"
      return false unless self.looks_like_key(key_id)
      
      # Let Errno::ECONNREFUSED exceptions bubble up here
      key = self.find_by_key(db, key_id)
      return false if key.nil?

      !key.disabled?
    end

    def self.clear_cached_auth(key_id)
      cache_key = cache_key(key_id)
      previous = Rails.cache.read(cache_key)
      Rails.cache.delete(cache_key)
      previous
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
