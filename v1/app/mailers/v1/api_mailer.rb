module V1
  class ApiMailer < ActionMailer::Base

    def api_auth_info(args={})
      @recipient = args['owner']
      @key = args['key'].id
      mail(:to => @recipient, :subject => "Your DPLA API authentication details")      
    end
    
  end
end
