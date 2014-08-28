module Contentqa
  class Engine < ::Rails::Engine
    isolate_namespace Contentqa

    # engine_name 'contentqa_app'

    # Add the engine's settings to RailsConfig
    initializer 'settings' do
      Contentqa::Settings = Kernel.const_get(RailsConfig.const_name)

      setting_files = [self.root.join('config', 'settings.yml'),
                       self.root.join('config', 'settings', "#{Rails.env}.yml"),
                       self.root.join('config', 'environments', "#{Rails.env}.yml"),
                       self.root.join('config', 'settings.local.yml'),
                       self.root.join('config', 'settings', "#{Rails.env}.local.yml"),
                       self.root.join('config', 'environments', "#{Rails.env}.local.yml")]

      setting_files.each { |f| Contentqa::Settings.add_source!(f.to_s) }
      Contentqa::Settings.reload!
    end
  end
end
