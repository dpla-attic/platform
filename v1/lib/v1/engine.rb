module V1
  class Engine < ::Rails::Engine
    isolate_namespace V1

    # prefix route helper functions with v1_api. (e.g. v1_api.root_path)
    engine_name 'v1_api'

    initializer "v1.tire_config" do
      V1::Config.initialize_tire
    end

  end
end
