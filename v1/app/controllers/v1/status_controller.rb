module V1

  class StatusController < ApplicationController
    rescue_from Errno::ECONNREFUSED, :with => :connection_refused
    #TODO: should we also rescue_from ServiceUnavailableSearchError and re-raise that in StatusMonitor?
    def repository
      render_status(StatusMonitor.repository)
    end

    def render_status(status={})
      message = status['message']
      http_status = status['status'] || 'ok'
      
      log_problem(status) if http_status != 'ok'
      render :json => {'message' => message}, 'status' => http_status.to_sym
    end

    def log_problem(status={})
      logger.warn "STATUS:#{params['action']}: HTTP #{status['status']} - #{status['message']}"
    end

    def connection_refused(exception)
      error = ServiceUnavailableSearchError.new
      render_status('message' => e.message, 'status' => error.http_status)
      # render_error(ServiceUnavailableSearchError.new, params)
      #        status = :service_unavailable
      #        message = e.to_s
    end

  end

end
