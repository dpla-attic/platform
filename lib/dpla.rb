module Dpla

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

