require 'v1/application_controller'

module V1
  class ApiKeyController < ApplicationController
    #TODO: rescue_from here

    def show_placeholder
      message = "Error: If you are attempting to request an API key, you need to send a POST request to "
      message += "this API endpoint, not a GET request like this one. "
      message += "Please see http://dp.la/info/developers/codex/policies/#get-a-key"
      render :json => {:message => message}, :status => :error
    end

    def index
      #TODO: add a helpful error message (and define a route)
      render :text => 'This page intentionally left blank. Print it out for a free piece of paper!'
    end

    def show
      owner = params['owner']
      status = :ok
      message = 'API key sent via email'

      key = ApiAuth.find_api_key_by_owner(owner)
      if key
        email_key(owner, key)
      else        
        status = :not_found
        message = 'API key not found'
      end
      
      respond_to do |format|
        format.json { render :json => {:message => message}, :status => status }
      end
    end

    def create
      owner = params['owner']
      
      begin
        # TODO: don't create if a key already exists for this user, just email it and return HTTP 200
        key = ApiAuth.create_api_key(owner)
        Rails.logger.info "API_KEY: Created API key for #{owner}: #{key.to_hash}"

        email_key(owner, key)

        message = 'API key created and sent via email. Be sure to check your Spam folder, too.'
        status = :created
        error = nil
      rescue RestClient::BadRequest => e
        message = "API key creation failed due to an internal error. Please try again later."
        status = :error
        error = e
      rescue Net::SMTPSyntaxError => e
        message = "API key created but could not be sent via email. Perhaps you mis-typed your email address?"
        status = :error
        error = e
      rescue => e
        message = "API key created but could not be sent via email due to an unexpected error."
        status = :error
        error = e
      end

      Rails.logger.warn "API_KEY: Error for key: #{key}: #{error}" if status != :created
      
      respond_to do |format|
        format.json { render :json => {:message => message}, :status => status }
      end
    end

    
    private
    
    def email_key(owner, key)
      ApiMailer.api_auth_info('owner' => owner, 'key' => key).deliver
    end
    
  end
end
