When /^I raise "(.*?)"$/ do |arg1|
  @params = { 'raise' => arg1 }
end

Then /^I should get http status code "(.*?)"$/ do |arg1|
  item_query(@params)
  expect(page.status_code.to_s).to eq(arg1)
end

When /^I take the API service down for maintenance$/ do
  system("touch #{get_maintenance_file}")
end

When /^I bring system back from maintenance$/ do
  system("rm #{get_maintenance_file}")
end

Given /^I request the API$/ do
  item_query(@params)
end
