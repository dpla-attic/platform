require_dependency "v1/application_controller"
require 'v1/item'

module V1
  class SearchController < ApplicationController

    def items
      begin
        results = V1::Item.search(params)
        render :json => render_json(results, params)
      rescue SearchError => error
        render :json => {:message => error.message}, :status => error.http_code
      end        
    end

    def fetch
      ids = params[:ids].split(',')
      results = V1::Item.fetch(ids)
      render :json => render_json(results, params)
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
