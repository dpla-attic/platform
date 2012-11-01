module V1
  class ApplicationController < ActionController::Base
    before_filter :check_for_raised_errors

    def check_for_raised_errors
      render_and_return_status_code(params[:raise]) if params[:raise].present?
    end

    def render_and_return_status_code(code)

      valid_codes = %w(200 400 401 404 406 429 500 503)

      status = valid_codes.include?(code) ? code : 500
      
      render :text => "Raised Mock Error", :status => status 

      return false
    
    end
  end
end
