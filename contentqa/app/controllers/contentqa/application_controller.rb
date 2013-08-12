require 'v1/api_auth'

module Contentqa
  
  class ApiAuthFailed < Exception; end

  API_AUTH_OWNER = 'aa22-qa-app@dp.la'
  
  class ApplicationController < ActionController::Base
    before_filter :fetch_qa_api_auth
    rescue_from ApiAuthFailed, :with => :api_auth_failed

    def fetch_qa_api_auth
      @@api_auth_key ||= V1::ApiAuth.find_api_key_by_owner(API_AUTH_OWNER)
    end
    
    def baseuri
      request.protocol + request.host_with_port
    end

    #TODO: use v1_api.items_url
    def item_fetch_link(id)
      baseuri + v1_api.items_path + '/' + id + "?api_key=#{ @@api_auth_key }"
    end

    def item_search(params={})
      api_query(baseuri + v1_api.items_path(params))
    end
    
    def item_fetch(id)
      api_query(item_fetch_link(id))
    end

    def api_query(uri)
      uri += "&api_key=#{ @@api_auth_key }"
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
      logger.warn "Error: API auth failed for #{ self.class} with api key: #{@@api_auth_key || '(none)'}"
      render :text => "Error: API auth failed, which should never happen. Perhaps the QA application's API key was never imported?", :status => :error
    end
    
  end
end
