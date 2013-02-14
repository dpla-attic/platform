module Contentqa
  class ApplicationController < ActionController::Base

    def baseuri
      request.protocol+request.host_with_port()
    end

    def item_fetch_link(id)
      baseuri + v1_api.items_path() + '/' + id
    end

    def item_search(params={})
      HTTParty.get(baseuri + v1_api.items_path(params)).parsed_response
    end
    
    def item_fetch(id)
      HTTParty.get(item_fetch_link(id)).parsed_response
    end

  end
end
