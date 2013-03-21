require_dependency "v1/application_controller"

#TODO: eliminate new duplication between resources here and break this into V1::ItemsController and V1::CollectionsController (to invert the current topology)

module V1
  class SearchController < ApplicationController
    rescue_from Errno::ECONNREFUSED, :with => :connection_refused

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
    
    def links; end

  end
end
