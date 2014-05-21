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
