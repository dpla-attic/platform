module V1

  class ApplicationController < ActionController::Base
    before_filter :check_for_raised_errors

    def check_for_raised_errors
      #      render_and_return_status_code(params[:raise])
      return true if params[:raise].blank?

      status = %w(200 400 401 404 406 429 500 503).include?(params[:raise]) ? params[:raise] : 500

      render :json => render_as_json({:message => "Raised Mock Error"}, params), :status => status

      return false
    end

    def render_and_return_status_code(code)
    end
    
    def authenticate
      api_key = params['api_key']
      if !authenticate_api_key(api_key)
        logger.info "UnauthorizedSearchError for api_key: #{ api_key || '(none)' }"
        render_error(UnauthorizedSearchError.new, params)
      end
      # Delete this key now that we're done with it
      params.delete 'api_key'
    end

    def authenticate_api_key(key_id)
      logger.debug "API_AUTH: authenticate_key firing for key: '#{key_id}'"
      
      if Config.skip_key_auth_completely?
        logger.warn "API_AUTH: skip_key_auth_completely? is true"
        return true
      end

      if Config.accept_any_api_key? && key_id.to_s != ''
        logger.warn "API_AUTH: accept_any_api_key? is true and an API key is present"
        return true
      end

      begin
        return Rails.cache.fetch(ApiKey.cache_key(key_id)) do
          ApiAuth.authenticate_api_key(key_id)
        end
      rescue Errno::ECONNREFUSED
        # Avoid refusing api auth if we could not connect to the api auth server
        logger.warn "API_AUTH: Connection Refused trying to auth api key '#{key_id}'"
        return true
      end
    end    

    def render_as_json(results, params)
      # Handles optional JSONP callback param
      conversion = results.is_a?(Hash) ? :to_json : :to_s

      if params['callback'].present?
        params['callback'] + '(' + results.send(conversion) + ')'
      else
        results.send(conversion)
      end
    end

    def render_error(e, params)
      render :json => render_as_json({:message => e.message}, params), :status => e.http_status
    end

  end

end
