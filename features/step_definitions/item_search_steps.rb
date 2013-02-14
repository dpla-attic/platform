Then /^the API should return (\d+) items with "(.*?)"$/ do |count, keyword|
  json = item_query_to_json(@params)
  expect(json).to have(count).items
  json.each_with_index do |result, idx|
    expect(result).to have_content(keyword)
  end
end

When /^I search for "(.*?)"( in the "(.*?)" field)?$/ do |keyword, junk, query_field|
  @query_field = query_field || 'q'
  @query_string = keyword
  @params = { @query_field => @query_string }
end

When /^I search the "(.*?)" field for records with a date between "(.*?)" and "(.*?)"$/ do |field, start_date, end_date|
  @params = {
    "#{field}.after" => start_date,
    "#{field}.before" => end_date,
  }
end

When /^I search the "(.*?)" field for records with a date (before|after) "(.*?)"$/ do |field, modifier, target_date|
  @params = { "#{field}.#{modifier}" => target_date }
end

Then /^the API should return records? (.*?)$/ do |id_list|
  json = item_query_to_json(@params, true)

  if json.nil?
    raise RSpec::Expectations::ExpectationNotMetError, "Query unexpectedly returned zero results for params: #{@params}"
  end

  expect(
    json.map {|doc| doc['_id'] }
  ).to match_array id_list.split(/,\s*/)
end

Then /^the API should return no records$/ do
  json = item_query_to_json(@params)
  expect(json.size).to eq 0
end

Given /^the default search radius for location search is (\d+) miles$/ do |arg1|
  expect(V1::Searchable::Filter::DEFAULT_GEO_DISTANCE).to eq "#{arg1}mi"
end

When /^I search for records with "(.*?)" near coordinates "(.*?)"( with a range of (\d+) miles)?$/ do |field, lat_long, junk, distance|
  @params = {field => lat_long}
  if distance
    distance_field = field.gsub(/^(.+)\.(.+)$/, '\1.distance')
    @params[distance_field] = distance + 'mi'
  end
end

Then /^the API should not return record (.+)$/ do |id|
  json = item_query_to_json(@params)
  expect(
    json.map {|doc| doc['_source']['_id'] }.include?(id)
  ).to be_false
end
