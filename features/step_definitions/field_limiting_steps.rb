When /^I search with "(.*?)" as the value of the fields parameter$/ do |vals|
  @params = { 'fields' => vals }
end

Then /^I should get results with only "(.*?)" as fields$/ do |vals|
  json = item_query_to_json(@params)
  fields = vals.split(',')
  json.each do | doc |
    expect(doc.keys.count).to eq(fields.count)
    expect(doc.keys - fields == []).to eq(true)
  end
end

Then /^I should get a (\d+) http response$/ do |code|
  get "/api/v1/items?#{ @params.to_param }"
  expect(last_response.status.to_s).to eq(code)
end
