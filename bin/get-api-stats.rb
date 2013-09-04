#!/usr/bin/env ruby
require 'httparty'
require 'json'

def main(argv)
  #  file, key_repo args are required. excluded_keys is optional csv list of keys to omit.
  # The string "none" is allowed on the cmd line to ignore key-less requests
  if $stdin.tty?
    $stderr.puts "Error: logfile(s) must be supplied via stdin"
    $stderr.puts "Usage: cat *.log | #{$0} $api_key_auth_view_url ['excludedapikey1,excludedapikey2']"
    exit 1
  end

  api_keys_view, excluded_keys = argv
  verify_api_keys_view(api_keys_view)
  
  raise "Missing 2nd arg which should be full URL to find_by_owner repository view" unless api_keys_view

  results = analyze_file(excluded_keys)
  owners_to_hits = lookup_keys(results[:keys], api_keys_view)
  render_results(results, owners_to_hits)
end

def verify_api_keys_view(api_keys_view)
  # verify API keys are fetchable before bothering to parse all the input logs
  if fetch_api_keys(api_keys_view).nil?
    $stderr.puts "Error fetching API keys from #{api_keys_view}"
    exit 1
  end

end

def fetch_api_keys(api_keys_view)
  JSON.parse(HTTParty.get(api_keys_view).parsed_response)['rows']
end

def lookup_keys(key_hits, api_keys_view)
  rows = fetch_api_keys(api_keys_view)
  
  keys_to_owners = {}
  rows.each do |repo_key|
    # this is actually key_id => owner
    keys_to_owners[repo_key['id']] = repo_key['key']
  end

  puts divider
  
  keys_to_owners.sort_by {|k,v| v}.each do |key_id,owner|
    puts "#{key_id}#{sep}#{owner}"
  end

  # for each key we have hits for, create owner -> hits
  owners_to_hits = {}
  key_hits.each do |key_id,hits|
    #    puts "#{key_id} #{hits} -> #{keys_to_owners[key_id]}"
    owners_to_hits[ keys_to_owners[key_id] ] = hits
  end
  
  owners_to_hits
end

def analyze_file(excluded_keys)
  skip_keys = excluded_keys.to_s.split(/,\s*/).inject({}) {|memo,key| memo[key] = true; memo}
  puts "Omitting keys: #{skip_keys.keys}"

  # Rails log format
  target_regexp = /^Started GET "([^"]+)" for .* at (\d{4}-\d{2}-\d{2})/
  last_date = nil
  dates = {}
  keys = {}
  
  begin
    $stdin.each_line do |line|
      next unless line =~ target_regexp

      url, date = $1, $2

      $stderr.puts date if last_date != date
      last_date = date
      
      url =~ /\bapi_key=(\w+)\b/
      key = $1 || 'none'  #'none' can be passed on the cmd line

      #BUG: doesn't properly ignore 'none' 
      next if skip_keys[key]

      dates[date] ||= 0
      dates[date] += 1

      keys[key] ||= 0
      keys[key] += 1

    end
  rescue Errno::EPIPE
  end

  {:dates => dates, :keys => keys}
end

def render_results(results, owners_to_hits)
  
  puts divider

  dates = results[:dates]
  dates.sort.each do |date,count|
    puts "#{date}#{sep}#{count}"
  end
  
  puts divider
  owners_to_hits.sort_by {|k,v| v}.reverse.each do |key,count|
    puts "#{key||'none'}#{sep}#{count}"
  end
end

def divider
  "-" * 20
end

def sep
  "\t"
end


main(ARGV)

