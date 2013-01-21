When /^request the "(.*?)" facet$/ do |arg1|
  @params['facets'] = arg1
end

Then /^the API returns the "(.*?)" facets$/ do |arg1|
  facets = arg1.split(/,\s*/)
  @results = item_query(@params)
#  puts @results.pretty_inspect
#   dates = @results['facets'][ @results['facets'].keys.first ]['entries']
# #  puts "entries: #{dates.inspect}"
#   dates.each do |tuple|
#     time = tuple['time']
#     puts "Time/Date: #{time} / #{ Time.at( (time)/1000 ).to_date }"
#   end
                                   
  expect(@results['facets'].keys).to match_array facets
end

Then /^the "(.*?)" terms facets contains items for every unique field within the (search index|results set)$/ do |facet_list, junk|
  @facets = facet_list.split(/,\s*/)
  @source = compute_facets(@facets, @query_string)
  @facets.each do |facet|
    expect(
           @results['facets'][facet]['terms'].map {|f| f['term'] }
           ).to match_array @source[facet].keys
  end
end

Then /^the "(.*?)" date facet contains items for every unique field within the (search index|results set)$/ do |facet_list, junk|
  @facets = facet_list.split(/,\s*/)
  @source = compute_facets(@facets, @query_string)

  @facets.each do |facet_name|
    # Simplify structure of this facet, from the results set
    returned_facets = @results['facets'][facet_name]['entries'].inject({}) do |memo, tuple|
      memo[tuple['time']] = tuple['count']
      memo
    end

    # Compare hashes
    expect( returned_facets ).to eq @source[facet_name]
  end

end

#TODO: These steps, and the corresponding uc010 feature, could use some consolidation
Then /^each item within each facet contains a count of matching "(.*)" facet items$/ do |facet_type|
  @facets.each do |facet|
    # puts "FACET: #{facet}"
    # puts "SRCET: #{@source[facet]}"
    expect(
           @results['facets'][facet]['terms'].map {|f| [f['term'], f['count']] }.flatten
           ).to match_array @source[facet].flatten
  end
end

Then /^the API returns items that contain the query string$/ do
  # Admittedly, a fairly loose test.
  results = item_query(@params)
  results['docs'].each do |doc|
    expect(doc.values.any? {|value| value =~ /#{@query_string}/} ).to be_true
  end
end

