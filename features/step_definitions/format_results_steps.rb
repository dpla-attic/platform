When /^I pass callback param "(.*?)" to a search for "(.*?)"$/ do |callback, keyword|
  @callback = callback
  @params.merge!({ 'q' => keyword, 'callback' => callback })
end

Then(/^I should get a valid JSON response$/) do
  #Hackish test to see if we've already run a request as part of this test
  status_code = page.status_code rescue $!
  if status_code.is_a? Rack::Test::Error
    resource_query(@resource, @params, false)
  end

  json = page.source
  
  if @callback
    json =~ /^#{@callback}\((.+)\)$/m
    json = $1
  end
  
  expect(json).not_to be_nil
  expect {
    JSON.parse(json) 
  }.not_to raise_error
end

Then /^the API response should start with "(.*?)"$/ do |callback|
  @resource = 'item'
  resource_query(@resource, @params)
  expect(page.source).to match /^#{callback}\(/
end
