require_relative 'search_engine'
require_relative 'search_engine/river'
require_relative 'repository'

module V1

  module StatusMonitor

    def self.repository
      status = 'ok'
      message = nil

      begin
        response = JSON.parse(Repository.service_status(true))
        
        if response['doc_count'].to_s == ''
          status = :error
          message = response.to_s
        end
      rescue Errno::ECONNREFUSED => e
        #TODO: handle this in controllers or even reraise a ServiceUnavailableSearchError.new?
        status = :service_unavailable
        message = e.to_s
      rescue => e
        status = :error
        message = e.to_s
      end

      {'message' => message, 'status' => status}
    end

  end

end
