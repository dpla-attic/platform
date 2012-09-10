namespace :dpla do

  desc "Verify all required config files exist"
  task :check_config do
    #TODO: Get this to run all API engines' check_config rake tasks too.
    # using something like: Dir.glob('lib/rake/*.rake').each { |r| import r }
    require 'dpla'
    if Dpla.check_config( __FILE__, %w( config/database.yml ) )
      puts "OK. All required DPLA config files present."
    end
  end

end
