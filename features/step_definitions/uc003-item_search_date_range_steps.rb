When /^I search the "(.*?)" field for records with a date between "(.*?)" and "(.*?)"$/ do |field, start_date, end_date|
  params = {
    "#{field}.after" => start_date,
    "#{field}.before" => end_date,
  }
  @json = item_query_to_json(params)
end

When /^I search the "temporal" field for records with a date (before|after) "(.*?)"$/ do |modifier, target_date|
  params = { "temporal.#{modifier}" => target_date }
  @json = item_query_to_json(params)
end

Then /^the API should return records? (.*?)$/ do |id_list|
  expect(
         @json.map {|doc| doc['_source']['_id'] }
         ).to match_array id_list.split(/,\s?/)
end

Then /^the API should return no records$/ do
  expect(@json.size).to eq 0
end



