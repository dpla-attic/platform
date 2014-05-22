Given /^that I have a valid API key$/ do
  @params['api_key'] = @valid_api_key
end

Given /^the default page size is (\d+)$/ do |arg1|
  expect(V1::Searchable::DEFAULT_PAGE_SIZE ).to eq 10
end

Given /^the default test dataset is loaded$/ do
  expect(Tire.index(V1::Config.search_index).exists?).to be_true
end

Given(/^the default test field boosts are defined$/) do
  # Pull field_boosts from dpla.yml.travis so integration tests are guaranteed
  # to run with the same boosts when run in dev and in Travis
  begin
    config_file = File.expand_path("../../../v1/config/dpla.yml.travis", __FILE__)
    boosts = YAML.load_file(config_file)['field_boosts'] || {}
    V1::FieldBoost.stub(:all) { boosts }
  rescue => e
    raise "Error loading field_boosts from test config file #{config_file}: #{e}"
  end

end

When(/^I make an empty item\-search and the search endpoint times out$/) do
  @resource = 'item'
  V1::Item.stub(:wrap_results) { raise RestClient::RequestTimeout }
end

When /^I make an empty ((\w+)-)?search$/ do |_, resource|
  @resource = resource
end

When(/^set page to (\d+)$/) do |arg1|
  @params['page'] = arg1
end

When(/^set page_size to (\d+)$/) do |arg1|
  @params['page_size'] = arg1
end

When /^sort by "(.*?)"$/ do |arg1|
  @params['sort_by'] = arg1
end

When /^sort by pin "(.*?)"$/ do |arg1|
  @params['sort_by_pin'] = arg1
end

When(/^set sort_order to (\w+)$/) do |arg1|
  @params['sort_order'] = arg1
end

Then /^I should get http status code "(.*?)"$/ do |arg1|
  #Hackish test to see if we've already run a request as part of this test
  status_code = page.status_code rescue $!
  if status_code.is_a? Rack::Test::Error
    resource_query(@resource, @params, false)
  end
  
  if page.status_code.to_s != arg1
    puts "Params were    : #{ @params }"
    puts "Server Response: #{ page.source }"
  end

  expect(page.status_code.to_s).to eq(arg1)
end

Then /^I should get http status code "(.*?)" from the QA app$/ do |arg1|
  if page.status_code.to_s != arg1
    puts "Server Response: #{ page.source }"
  end

  expect(page.status_code.to_s).to eq(arg1)
end

