When /^I query with a raise parameter of "(.*?)"$/ do |arg1|
  @params.merge!({ 'raise' => arg1 })
end

When /^I take the API service down for maintenance$/ do
  create_maintenance_file
end

When /^I bring system back from maintenance$/ do
  remove_maintenance_file
end
