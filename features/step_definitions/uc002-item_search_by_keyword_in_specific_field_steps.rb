When /^I search for "(.*?)" in the "(.*?)" field$/ do |keyword, field|
  params = { field => keyword }
  @json = item_query_to_json(params)
end

