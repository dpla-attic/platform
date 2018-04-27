module V1
  class Engine < Rails::Engine
    isolate_namespace V1

    # prefix route helper functions with v1_api. (e.g. v1_api.root_path)
    engine_name 'v1_api'

    initializer 'configure_email_from_address' do
      ActionMailer::Base.default :from => Config.email_from_address
    end

  end
end
