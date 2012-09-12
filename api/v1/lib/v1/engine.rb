module V1
  class Engine < ::Rails::Engine
    isolate_namespace V1

    # prefix route helper functions with v1_api. (e.g. v1_api.root_path)
    engine_name 'v1_api'

    initializer "v1.tire_config" do
      Tire::Configuration.url(V1::Search.get_search_endpoint)
      Tire::Model::Search.index_prefix("test_") if Rails.env.test?
    end

  end
end
