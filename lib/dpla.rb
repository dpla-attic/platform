module Dpla

  # Dpla::API_ROLE gets populated by config/initializers/api_role.rb
  API_ROLE_SANDBOX = 'sandbox'
  API_ROLE_PRODUCTION = 'production'

  def self.get_api_role
    config_file = File.expand_path('../../config/api_role.yml', __FILE__)
    api_role = YAML.load_file(config_file)['api_role']

    if ![Dpla::API_ROLE_SANDBOX, Dpla::API_ROLE_PRODUCTION].include?(api_role)
      raise "Missing or invalid 'api_role' config value found in #{config_file}"
    end

    api_role
  end

  def self.check_config(base_file, files)
    # Used by rake tasks (dpla:check_config, etc) to detect whether a given API 
    # engine or the base application has been configured or not.
    config_ok = true
    files.each do |file|
      file_path = File.expand_path("../../../#{file}", base_file)
      if !File.exists?(file_path)
        puts "ERROR: Missing config file: #{file_path}"
        config_ok = false
      end
    end

    return config_ok
  end

end

