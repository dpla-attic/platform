require_dependency "v1/application_controller"

#TODO: eliminate new duplication between resources here and break this into V1::ItemsController and V1::CollectionsController (to invert the current topology)

module V1
  class SearchController < ApplicationController
    before_filter :authenticate!, :except => [:repo_status]  #, :links  #links is just here for testing auth
    rescue_from Errno::ECONNREFUSED, :with => :connection_refused

    def authenticate!
      # Authenticate their api_key for API access
      if !authenticate_api_key(params['api_key'])
        logger.info "UnauthorizedSearchError for api_key: #{ params['api_key'] || '(none)' }"
        e = UnauthorizedSearchError.new "Missing, invalid or inactive api_key param"

        render :json => render_json({:message => e.message}, params), :status => e.http_status
      end
      # Delete this key now that we're done with it
      params.delete 'api_key'
    end

    def items
      begin
        results = V1::Item.search(params)
        # TODO: Uncomment this when we have renamed the format field in the schema
        # respond_to do |format|
        #   format.json  { render :json => render_json(results, params) }
        # end
        render :json => render_json(results, params)
      rescue SearchError => e
        render :json => render_json({:message => e.message}, params), :status => e.http_status
      end
    end

    def fetch
      results = []
      begin 
        results = V1::Item.fetch(params[:ids].split(/,\s*/))
        status = 200
      rescue NotFoundSearchError => e
        status = e.http_status
      end
      render :json => render_json(results, params), :status => status
    end

    def collections
      begin
        results = V1::Collection.search(params)
        render :json => render_json(results, params)
      rescue SearchError => e
        render :json => render_json({:message => e.message}, params), :status => e.http_status
      end
    end

    def fetch_collections
      results = []
      begin 
        results = V1::Collection.fetch(params[:ids].split(/,\s*/))
        status = 200
      rescue NotFoundSearchError => e
        status = e.http_status
      end
      render :json => render_json(results, params), :status => status
    end

    def render_json(results, params)
      # Handles optional JSONP callback param
      if params['callback'].present?
        params['callback'] + '(' + results.to_json + ')'
      else
        results.to_json
      end
    end

    def repo_status
      status = :ok
      message = nil

      begin
        response = JSON.parse(V1::Repository.service_status(true))
        
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

      logger.warn "REPO_STATUS Check: #{message}" if message
      head status
    end
    
    def connection_refused
      logger.warn "search_controller#connection_refused handler firing"
      e = ServiceUnavailableSearchError.new
      render :json => render_json({:message => e.message}, params), :status => e.http_status
    end
    
    def authenticate_api_key(key_id)
      logger.debug "PHUNK: authenticate_key firing with key: '#{key_id}'"
      
      if V1::Config.skip_key_auth_completely?
        logger.warn "API_AUTH: skip_key_auth_completely? is true"
        return true
      end

      if V1::Config.accept_any_api_key? && key_id.to_s != ''
        logger.warn "API_AUTH: accept_any_api_key? is true and an API key is present"
        return true
      end

      #TODO: Rails.cache this
      begin
        return V1::Repository.authenticate_api_key(key_id)
      rescue Errno::ECONNREFUSED
        logger.warn "API_AUTH: Connection Refused trying to auth api key '#{key_id}'"
        return true
      end
    end    

    def links; end

  end
end
