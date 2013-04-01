module V1
  class ApiMailer < ActionMailer::Base
    default from: "api-support@dp.la"

    def api_auth_info(args={})
      @recipient = args['owner']
      @key = args['key']
      mail(:to => @recipient, :subject => "Your DPLA API authentication details")      
    end
    
  end
end
