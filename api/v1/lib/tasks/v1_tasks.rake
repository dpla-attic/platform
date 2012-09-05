namespace :v1 do

  desc "Gets ES search cluster status"
  task :search_status do
    require 'v1'
    endpoint = V1::Search.get_search_endpoint
    # silly curl arguments to suppress the progress bar but let errors through
    puts `curl #{endpoint} -s -S`
  end

end
