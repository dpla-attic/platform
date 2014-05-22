When /^I ((\w+)-)search with "(.*?)" as the value of the fields parameter$/ do |junk, resource, fields|
  @resource = resource
  @params.merge!({ 'fields' => fields })
end

When(/^I limit the requested fields to "(.*?)"$/) do |fields|
  @params.merge!({ 'fields' => fields })
end

Then /^I should get results with only "(.*?)" as fields$/ do |fields|
  fields = fields.split(/,\s*/)
  json = item_query_to_json(@params)

  # Some docs may be missing some of the fields we requested, so we just test each doc
  # does *not* have any fields *except* the ones we requested. Clear as mud? :)
  json.each do | doc |
    expect( doc.keys - fields ).to eq []
  end
end

