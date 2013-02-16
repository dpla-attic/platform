module Contentqa
  class ApplicationController < ActionController::Base

    def baseuri
      request.protocol + request.host_with_port()
    end

    def item_fetch_link(id)
      baseuri + v1_api.items_path() + '/' + id
    end

    def item_search(params={})
      api_query(baseuri + v1_api.items_path(params))
    end
    
    def item_fetch(id)
      api_query(item_fetch_link(id))
    end

    def api_query(uri)
      search = HTTParty.get(uri, request_options)
      raise "API Request Error: #{ search.message }" unless search.code == 200
      search.parsed_response
    end

    def request_options
      if request.env['HTTP_AUTHORIZATION']
        user, pass = ActionController::HttpAuthentication::Basic::user_name_and_password(request)
        {:basic_auth => {:username => user, :password => pass}}
      else
        {}
      end
    end
    
  end
end
