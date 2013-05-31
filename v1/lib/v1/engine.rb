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

  end
end
