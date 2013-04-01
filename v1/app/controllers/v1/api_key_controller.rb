require_dependency "v1/application_controller"

module V1
  class ApiKeyController < ApplicationController
    #TODO: rescue_from here
    #TODO: More error handling and logging

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
      #TODO: implement a find_or_create_by_owner
      
      # TODO: don't create if a key already exists for this user, just email it and return HTTP 200
      # create it if it doesn't exist
      key = V1::Repository.create_api_key(owner)
      logger.debug "API_KEY: Created API key: #{key.to_hash}"

      # TODO: exception handling and logging here
      email_key(owner, key)
      message = 'API key created and sent via email'
      
      respond_to do |format|
        format.json { render :json => {:message => message}, :status => :created }
      end

    end

    
    private
    
    def email_key(owner, key)
      Rails.logger.warn "Emailing API keys temporarily disabled, but WOULD have sent: #{ {'owner' => owner, 'key' => key} }"
      return
      ApiMailer.api_auth_info('owner' => owner, 'key' => key).deliver
    end
    
  end
end
