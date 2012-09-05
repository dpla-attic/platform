require 'v1'

namespace :v1 do

  desc "Gets ES search cluster status"
  task :search_status do
    endpoint = V1::Search.get_search_endpoint
    # silly curl arguments to suppress the progress bar but let errors through
    puts `curl #{endpoint} -s -S`
  end

  desc "Diplays the search_endpoint the API is configured to use"
  task :search_endpoint do
    puts V1::Search.get_search_endpoint
  end

  desc "Checks that all required config files are in place"
  task :check_config do
    #TODO
  end
end
