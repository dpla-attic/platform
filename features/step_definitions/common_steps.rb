Given /^that I have a valid API key$/ do
  @params['api_key'] = @valid_api_key
end

Given /^the default page size is (\d+)$/ do |arg1|
  expect(V1::Searchable::DEFAULT_PAGE_SIZE ).to eq 10  #TODO: Not 100% expressive/useful here
end

Given /^the default test dataset is loaded$/ do
  expect(Tire.index(V1::Config::SEARCH_INDEX).exists?).to be_true
end

When /^I make an empty search$/ do
  #nothing to do
  true
end

When /^sort by "(.*?)"$/ do |arg1|
  @params['sort_by'] = arg1
end

When /^sort by pin "(.*?)"$/ do |arg1|
  @params['sort_by_pin'] = arg1
end

Then /^I should get http status code "(.*?)"$/ do |arg1|
  #TODO: simplify this to only check status
  resource_query('item', @params, false)

  if page.status_code.to_s != arg1
    puts "Server Response: #{ JSON.parse(page.source)['message'] || page.source }"
  end

  expect(page.status_code.to_s).to eq(arg1)
end

Then /^I should get http status code "(.*?)" from the QA app$/ do |arg1|
  if page.status_code.to_s != arg1
    puts "Server Response: #{ JSON.parse(page.source)['message'] || page.source }"
  end

  expect(page.status_code.to_s).to eq(arg1)
end

