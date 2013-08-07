When(/^do not provide an API key$/) do
  @params.delete 'api_key'
end

When(/^provide a invalid API key$/) do
  @params['api_key'] = @invalid_api_key
end

When(/^provide a disabled API key$/) do
  @params['api_key'] = @disabled_api_key
end

When(/^provide a valid API key$/) do
  @params['api_key'] = @valid_api_key
end

When(/^I request a new api key for "(.*?)" but use HTTP GET$/) do |email|
  visit "/v2/api_key/#{email}"
end

Then(/^I should get a JSON message containing "(.*?)"$/) do |message|
  json = JSON.parse(page.source)
  expect(json['message']).to match(/#{message}/)
end

