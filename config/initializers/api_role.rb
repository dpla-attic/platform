require 'dpla'

#TODO: Move this to Dpla.config
Dpla::API_ROLE = Dpla.get_api_role

if Dpla::API_ROLE == Dpla::API_ROLE_PRODUCTION && %w(test development).include?(Rails.env)
  raise "Cannot point application at production API in #{Rails.env} environment"
end
