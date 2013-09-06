Given(/^that I have a valid monitoring API key$/) do
  true  #TODO: implement
end

When(/^I fetch the "([^"]+)" status URL$/) do |service|
  visit_status_endpoint(service)
end

