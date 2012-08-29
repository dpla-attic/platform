module Dpla
  # Dpla::API_ROLE gets populated by config/initializers/api_role.rb
  API_ROLE_SANDBOX = 'sandbox'
  API_ROLE_PRODUCTION = 'production'

  def self.get_api_role
    config_file = File.expand_path('../../config/api_role.yml', __FILE__)
    api_role = YAML.load_file(config_file)['api_role']

    if api_role.nil? or ![Dpla::API_ROLE_SANDBOX, Dpla::API_ROLE_PRODUCTION].include?(api_role)
      raise "Missing or invalid 'api_role' config value found in #{config_file}"
    end

    api_role
  end

end

