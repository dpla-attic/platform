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

When(/^I visit the QA app homepage$/) do
  # TODO: try http://stackoverflow.com/questions/6536503/capybara-with-subdomains-default-host
  #visit '/qa/compare'
end




