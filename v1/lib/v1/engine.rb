module V1
  class Engine < Rails::Engine
    isolate_namespace V1

    # prefix route helper functions with v1_api. (e.g. v1_api.root_path)
    engine_name 'v1_api'

    initializer 'initialize_search_engine' do
      Config.initialize_search_engine
    end

    initializer 'configure_search_logging' do
      Config.configure_search_logging(Rails.env)
    end

    initializer 'configure_email_from_address' do
      ActionMailer::Base.default :from => Config.email_from_address
    end

    # Add the engine's settings to RailsConfig
    initializer 'settings' do
      setting_files = [self.root.join('config', 'settings.yml'),
                       self.root.join('config', 'settings', "#{Rails.env}.yml"),
                       self.root.join('config', 'environments', "#{Rails.env}.yml"),
                       self.root.join('config', 'settings.local.yml'),
                       self.root.join('config', 'settings', "#{Rails.env}.local.yml"),
                       self.root.join('config', 'environments', "#{Rails.env}.local.yml")
                      ].map { |path| path.to_s }

      settings_const = Kernel.const_get(RailsConfig.const_name)

      source_paths = settings_const.add_source!('nil')[0..-2].map { |source| source.path }
      source_paths = setting_files + source_paths
      
      RailsConfig.load_and_set_settings(source_paths)
      V1::Settings = Kernel.const_get(RailsConfig.const_name)
    end

  end
end
