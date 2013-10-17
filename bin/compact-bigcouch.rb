#!/usr/bin/env ruby

# Usage:  REPO=http://username:password@server:5984/my_db  bin/compact-bigcouch.rb
# Note the use of the "front door" BigCouch port.

require 'httparty'
require 'json'

def main(repo_uri)
  repo_uri = URI.parse(repo_uri)
  request_headers = {
    :headers => {"Content-Type" => "application/json"},
    :basic_auth => {:username => repo_uri.user, :password => repo_uri.password},
  }
  
  target_database = repo_uri.path.match(/^\/(.+)$/)[1]
  backdoor_host = 'http://' + repo_uri.host + ':' + (repo_uri.port + 2).to_s + '/'
  frontdoor_host = 'http://' + repo_uri.host + ':' + (repo_uri.port).to_s + '/'
  compact_api_prefix = backdoor_host + 'shards%2F'
  stats_repo_prefix = frontdoor_host + target_database

  raise "Compaction already running on host: #{repo_uri.host}" if compact_running(frontdoor_host)

  shards = JSON.parse(HTTParty.get(backdoor_host + '_all_dbs'))

  shards.shuffle.each do |path|
    next unless path =~ /^shards\/(.+)\/(#{target_database}\.\d+)$/
    shard, database = $1, $2

    url = compact_api_prefix + shard + '%2F' + database + '/_compact'
    logmsg "Compacting database shard #{shard}/#{database} -> #{url}"

    result = HTTParty.post(url, request_headers)
    raise "HTTP POST to compaction endpoint failed: '#{result}' for url: '#{url}'" unless result['ok']
    
    while true do
      sleep 30
      break if !compact_running(frontdoor_host)
      logmsg "running..."
    end
    
  end
end

def logmsg(msg)
  puts "[#{Time.now.to_s}] #{msg}"
end

def compact_running(host)
  # Note that this API endpoint lies roughly 5% of the time: JSON.parse(HTTParty.get(endpoint))['compact_running']
  # That makes it completely unusable for this check
  return JSON.parse(HTTParty.get(host + '_active_tasks')).any? {|t| t['type'] == "Database Compaction"}
end

raise "Missing required REPO env variable with repository/database URL" if ENV['REPO'].nil?
main(ENV['REPO'])

