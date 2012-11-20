When /^I search for "(.*?)"$/ do |keyword|
  @params = { 'q' => keyword }
end

Then /^the API should return (\d+) items with "(.*?)"$/ do |count, keyword|
  json = item_query_to_json(@params)
  expect(json).to have(count).items
  json.each_with_index do |result, idx|
    expect(result).to have_content(keyword)
  end
end

When /^I search for "(.*?)" in the "(.*?)" field$/ do |keyword, field|
  @params = { field => keyword }
end

When /^I search the "(.*?)" field for records with a date between "(.*?)" and "(.*?)"$/ do |field, start_date, end_date|
  @params = {
    "#{field}.after" => start_date,
    "#{field}.before" => end_date,
  }
end

When /^I search the "temporal" field for records with a date (before|after) "(.*?)"$/ do |modifier, target_date|
  @params = { "temporal.#{modifier}" => target_date }
end

Then /^the API should return records? (.*?)$/ do |id_list|
  json = item_query_to_json(@params)
  expect(
    json.map {|doc| doc['_id'] }
  ).to match_array id_list.split(/,\s?/)
end

Then /^the API should return no records$/ do
  json = item_query_to_json(@params)
  expect(json.size).to eq 0
end

Given /^the default search radius for location search is (\d+) miles$/ do |arg1|
  expect(V1::Searchable::Filter::DEFAULT_SPATIAL_DISTANCE).to eq "#{arg1}mi"
end

When /^I search for records with location near coordinates "(.*?)"( with a range of (\d+) miles)?$/ do |lat_long, junk, distance|
  @params = {'spatial.coordinates' => lat_long}
  @params['spatial.distance'] = distance + 'mi' if distance
end

Then /^the API should not return record (.+)$/ do |id|
  json = item_query_to_json(@params)
  expect(
    json.map {|doc| doc['_source']['_id'] }.include?(id)
  ).to be_false
end
