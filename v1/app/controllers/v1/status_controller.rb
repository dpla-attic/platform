module V1

  class StatusController < ApplicationController
    rescue_from Exception, :with => :generic_exception_handler
    rescue_from Errno::ECONNREFUSED, :with => :connection_refused

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
      render_status('message' => exception.message, 'status' => error.http_status)
    end

    def generic_exception_handler(exception)
      error = ServiceUnavailableSearchError.new 
      render_status('message' => exception.message, 'status' => error.http_status)
    end
      
  end

end
