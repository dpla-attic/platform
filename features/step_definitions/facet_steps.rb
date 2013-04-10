When /^request the "(.*?)" facet$/ do |arg1|
  @params['facets'] = arg1
end

When /^request facet size of "(.*?)"$/ do |arg1|
  @params['facet_size'] = arg1
end

When(/^filter facets on "(.*?)"$/) do |facet_list|
  @params['filter_facets'] = facet_list
end

Then(/^the API returns facets with the filtered values "(.*?)"$/) do |arg1|
  expected_terms = arg1.split('|').map {|t| t.downcase}

  @results = resource_query(@resource, @params)
  if !@results['facets']
    # if it goes wrong, it goes wrong here
    raise Exception, "Test error: No facets found\nResponse: #{@results['message']}"
  end

  facets = @results['facets'][ @params['facets'] ]
  returned_terms = facets['terms'].map {|t| t['term'].downcase}

  expect(returned_terms).to match_array(expected_terms)
end


Then /^the "(.*?)" terms facets contains the requested number of facets$/ do |facet_list|
  @facets = facet_list.split(/,\s*/)
  @facets.each do |facet|
    expect( @results['facets'][facet]['terms'].size.to_s ).to eq @params['facet_size']
  end
end

Then /^the "(.*?)" date facets contains the requested number of facets$/ do |facet_list|
  @facets = facet_list.split(/,\s*/)
  @facets.each do |facet|
    expect( @results['facets'][facet]['entries'].size.to_s ).to eq @params['facet_size']
  end
end

Then /^the API returns the "(.*?)" facets$/ do |arg1|
  facets = arg1.split(/,\s*/)
  @results = resource_query('item', @params)
  if !@results['facets']
    # if it goes wrong, it goes wrong here
    raise Exception, "Test error: No facets found\nResponse: #{@results['message']}"
  end

  expect(@results['facets'].keys).to match_array facets
end

Then /^the "(.*?)" terms facets contains items for every unique field within the (search index|results set)$/ do |facet_list, junk|
  @facets = facet_list.split(/,\s*/)
  @source = compute_facet_counts(@facets, @query_string)
  @facets.each do |facet|
    expect(
           @results['facets'][facet]['terms'].map {|f| f['term'] }
           ).to match_array @source[facet].keys
  end
end

Then /^the "(.*?)" date facet contains items for every unique field within the (search index|results set)$/ do |facet_list, junk|
  @facets = facet_list.split(/,\s*/)
  @source = compute_facet_counts(@facets, @query_string)

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
    expect(
           @results['facets'][facet]['terms'].map {|f| [f['term'], f['count']] }.flatten
           ).to match_array @source[facet].flatten
  end
end

Then /^the API returns items that contain the query string$/ do
  # Admittedly, a fairly loose test.
  results = resource_query('item', @params)

  results['docs'].each do |doc|
    expect( doc.to_s =~ /#{@query_string}/i ).to be_true
  end
end

