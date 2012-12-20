require_dependency "v1/application_controller"

module V1
  class SearchController < ApplicationController
    rescue_from Errno::ECONNREFUSED, :with => :connection_refused

    def items
      begin
        results = V1::Item.search(params)
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

    def render_json(results, params)
      # Handles optional JSONP callback param
      if params['callback'].present?
        params['callback'] + '(' + results.to_json + ')'
      else
        results.to_json
      end
    end
    
    def connection_refused
      e = ServiceUnavailableSearchError.new
      render :json => render_json({:message => e.message}, params), :status => e.http_status
    end
    
    def links; end

  end
end
