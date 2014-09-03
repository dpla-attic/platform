module Contentqa
  class Engine < ::Rails::Engine
    isolate_namespace Contentqa

    # engine_name 'contentqa_app'

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
      Contentqa::Settings = Kernel.const_get(RailsConfig.const_name)
    end
  end
end
