require_dependency "v1/application_controller"

module V1
  class ApiKeyController < ApplicationController
    #TODO: rescue_from here

    def show
      owner = params['owner']
      status = :ok
      message = 'API key sent via email'

      key = V1::Repository.find_api_key_by_owner(owner)
      if key
        email_key(owner, key)
      else        
        status = :not_found
        message = 'API key not found'
      end
      
      respond_to do |format|
        format.json { render :json => {:message => message}, :status => :ok }
      end
    end

    def create
      owner = params['owner']
      
      # TODO: don't create if a key already exists for this user, just email it and return HTTP 200
      key = V1::Repository.create_api_key(owner)
      Rails.logger.info "API_KEY: Created API key for #{owner}: #{key.to_hash}"

      message = 'API key created and sent via email'
      status = :created
      error = nil

      begin
        email_key(owner, key)
      rescue Net::SMTPSyntaxError => e
        message = "API key created but could not be sent via email. Perhaps you mis-typed your email address?"
        status = :error
        error = e
      rescue => e
        message = "API key created but could not be sent via email due to an error."
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
