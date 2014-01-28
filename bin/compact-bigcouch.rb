#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'getoptlong'

opts = GetoptLong.new(
  [ '--database', '-d', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--shard', '-s', GetoptLong::REQUIRED_ARGUMENT ],  # Example: e0000000-ffffffff
  [ '--only', '-o', GetoptLong::REQUIRED_ARGUMENT ],  # --only database, or --only view
)

params = {}
opts.each {|opt, arg| params[opt.gsub(/^--/, '')] = arg }

raise "Missing required --database arg with repository/database URL" if params['database'].nil?

def get(url)
  Net::HTTP.get(URI(url))
end

def post(url, request_headers)
  # url can be a string or a URI instance
  #TODO: convert to taking a full URI instance
  uri = URI(url)
  req = Net::HTTP::Post.new(uri.path)
  req["Content-Type"] = "application/json"
  if request_headers.any?
    req.basic_auth request_headers[:username], request_headers[:password]
  end

  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end
  
  case res
  when Net::HTTPSuccess, Net::HTTPRedirection
    true
  else
    raise "HTTP POST call failed: #{ res.value }"
  end
end


def get_shards(uri)
  JSON.parse(get(uri.to_s + '_all_dbs'))
end

def run_view_cleanup(database_url)
  post(database_url.to_s + '/_view_cleanup', {})
end

def get_backdoor_uri(repo_uri)
  uri = repo_uri.dup
  uri.path = '/'
  uri.port += 2
  uri
end
  
def main(params)
  repo_uri = URI.parse(params['database'])
  request_headers = {
    :username => repo_uri.user,
    :password => repo_uri.password
  }
  
  target_database = repo_uri.path.split('/')[1]
  backdoor_host = get_backdoor_uri(repo_uri)
  frontdoor_host = repo_uri.dup
  frontdoor_host.path = '/'

  if compaction_status(frontdoor_host)
    puts "Compaction already running on #{repo_uri.host}: #{compaction_status(frontdoor_host)}"
    exit 0
  end

  # Always start with view compaction for this database
  run_view_cleanup(repo_uri)
  design_docs = get_design_docs(frontdoor_host, target_database).shuffle

  get_shards(backdoor_host).shuffle.each do |path|
    next unless path =~ /^shards\/(.+)\/(#{target_database}\.\d+)$/
    shard, database = $1, $2
    next if params['shard'] && params['shard'] != shard

    base_url = backdoor_host.to_s + 'shards%2F' + shard + '%2F' + database + '/_compact'
    target_urls = []

    if params['only'] != 'view'
      target_urls << base_url
    end
    if params['only'] != 'database'
      target_urls.concat design_docs.map {|doc| base_url + '/' + doc}
    end

    target_urls.flatten.each do |url|
      logmsg "Compacting: #{url}"
      post(url, request_headers)
      loop_delay(frontdoor_host)
    end
    
  end

end

def get_design_docs(host, database)
  list_url = host.to_s + database + '/_all_docs?startkey=%22_design/%22&endkey=%22_design0%22'
  JSON.parse(get(list_url))['rows'].map do |hash|
    hash['key'].sub(/^_design\//, '')
  end
end

def loop_delay(frontdoor_host)
  start_time = Time.now.to_i
  while true do
    sleep 5
    status = compaction_status(frontdoor_host, start_time)
    break if status.nil?

    logmsg status
  end
end

def compute_eta(start_time, message)
  # Compute a rough ETA. The math only really makes sense for database compactions, not views
  if message =~ /\((\d+)%\)/
    return if $1.to_i == 0
    
    percentage = $1.to_i * 0.01
    elapsed = Time.now.to_i - start_time
    total_runtime = elapsed / percentage  #total time this run should take

    return (total_runtime - elapsed).to_i
  end
end

def logmsg(msg)
  puts "[#{Time.now.to_s}] #{msg}"
end

def compaction_status(base_endpoint, start_time=nil)
  # This assumes that your bigcouch node is set to include that node's `hostname`
  # value in that node's vm.args config value for the -name config variable
  hostname = base_endpoint.host
  json = JSON.parse(get(base_endpoint.to_s + '_active_tasks'))
  entry = json.detect {|x| x['node'] =~ /\b#{hostname}\b/ && x['type'] =~ /Compaction$/}

  entry.nil? ? nil :  "#{ entry['task'] } - #{entry['status'] }"
end

main(params)

