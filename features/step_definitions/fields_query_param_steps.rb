When /^I search with "(.*?)" as the value of the fields parameter$/ do |vals|
  @params = { 'fields' => vals }
end

Then /^I should get results with only "(.*?)" as fields$/ do |vals|
  #NOTE: Any field tested by this step MUST have a value (even if they are empty string
  # or null) for *every* document in the test dataset. ElasticSearch won't return a 
  # field if it was not defined in the source JSON, which will cause this test to fail.
  json = item_query_to_json(@params)
  fields = vals.split(/,\s*/)
  json.each do | doc |
    expect(doc.keys).to match_array fields
  end
end

