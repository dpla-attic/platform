When /^I ((\w+)-)search with a raise parameter of "(.*?)"$/ do |junk, resource, arg1|
  @resource = resource
  @params.merge!({ 'raise' => arg1 })
end

When /^I take the API service down for maintenance$/ do
  create_maintenance_file
end

When /^I bring system back from maintenance$/ do
  remove_maintenance_file
end
