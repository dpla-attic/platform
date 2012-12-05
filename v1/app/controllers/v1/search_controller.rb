require_dependency "v1/application_controller"

module V1
  class SearchController < ApplicationController

    def items
      begin
        results = V1::Item.search(params)
        render :json => render_json(results, params)
      rescue SearchError => e
        render :json => render_json({:message => e.message}, params), :status => e.http_code
      end        
    end

    def fetch
      ids = params[:ids].split(',')
      results = []
      begin 
        results = V1::Item.fetch(ids)
        status = 200
      rescue
        status = 404
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
    
    def links
    end
  end
end
