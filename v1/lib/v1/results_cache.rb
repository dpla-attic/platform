require 'digest/md5'

module V1

  module ResultsCache

    class << self

      def base_cache_key(resource, action, key='')
        if key.respond_to? :sort
          key = key.sort.to_s
        end
        [
         'v2',
         resource,
         action,
         Digest::MD5.hexdigest(key)
        ].join('-')
      end

    end

  end

end
