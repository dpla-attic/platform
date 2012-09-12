module V1
  class Engine < ::Rails::Engine
    isolate_namespace V1

    # prefix route helper functions with v1_api. (e.g. v1_api.root_path)
    engine_name 'v1_api'

    initializer "v1.get_search_endpoint" do
      V1.config.search_endpoint = V1::Search.get_search_endpoint
    end

  end
end
