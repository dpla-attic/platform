When /^I ((\w+)-)search with a raise parameter of "(.*?)"$/ do |junk, resource, arg1|
  @resource = resource
  @params.merge!({ 'raise' => arg1 })
end
