module Contentqa
  
  class ApiAuthFailed < Exception; end

  class ApplicationController < ActionController::Base
    rescue_from ApiAuthFailed, :with => :api_auth_failed

    def baseuri
      request.protocol + request.host_with_port
    end

    #TODO: use v1_api.items_url
    def item_fetch_link(id)
      baseuri + v1_api.items_path + '/' + id + "?api_key=#{Settings.contentqa.api_key}"
    end

    def item_search(params={})
      api_query(baseuri + v1_api.items_path(params))
    end
    
    def item_fetch(id)
      api_query(item_fetch_link(id))
    end

    def api_query(uri)
      uri += "&api_key=#{Settings.contentqa.api_key}"
      search = HTTParty.get(uri, request_options)
      raise ApiAuthFailed if search.code == 401

      response = search.parsed_response
      if search.code != 200
        raise "API Query Error (HTTP #{search.code}): #{ response['message'] rescue response }"
      end

      response
    end

    def request_options
      if request.env['HTTP_AUTHORIZATION']
        user, pass = ActionController::HttpAuthentication::Basic::user_name_and_password(request)
        {:basic_auth => {:username => user, :password => pass}}
      else
        {}
      end
    end

    def api_auth_failed
      logger.warn "Error: API auth failed for #{ self.class} with api key: #{Settings.contentqa.api_key} || '(none)'}"
      render :text => "Error: API auth failed, which should never happen. Perhaps the QA application's API key was never imported?", :status => :error
    end
    
  end
end
