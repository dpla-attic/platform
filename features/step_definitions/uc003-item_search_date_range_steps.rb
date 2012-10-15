When /^I search the "(.*?)" field for records with a date between "(.*?)" and "(.*?)"$/ do |field, start_date, end_date|
  params = {
    "#{field}.start" => start_date,
    "#{field}.end" => end_date,
  }
  visit("/api/v1/items?#{ params.to_param }")
  @json = JSON.parse(page.source)
end

Then /^the API should return record "(.*?)"$/ do |id|
  expect(@json.first['_source']['_id']).to eq id
end
