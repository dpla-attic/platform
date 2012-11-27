Given /^the dataset exists$/ do
  expect(File.exist?V1::StandardDataset::ITEMS_JSON_FILE).to be(true)
end

When /^I have valid JSON in the test dataset$/ do
  @json = load_dataset
end

Then /^I should not get a dataset error$/ do
  expect{
    JSON.parse(@json)
  }.to_not raise_error(JSON::ParserError)
end

Given /^there are (\d+) items that contain the word "(.*?)" in the "(.*?)"$/ do |arg1, arg2, arg3|
  @json = load_dataset
  dataset = JSON.parse(@json)
  count = dataset.count {|el| el[arg3].to_s.scan(/#{arg2}/).any? }
  expect(count.to_s).to eq(arg1)
end

Given /^there is a metadata record "(.*?)" with "(.*?)" in the "(.*?)" field$/ do |arg1, arg2, arg3|
  @json = load_dataset
  dataset = JSON.parse(@json)
  grouped_dataset = dataset.group_by {|el| el["_id"]}
  expect(grouped_dataset.include?(arg1)).to be(true)
  expect(grouped_dataset[arg1].count).to be(1)
  expect(grouped_dataset[arg1][0].values_at(arg3).count).to be(1)
  expect(grouped_dataset[arg1][0].values_at(arg3).include?(arg2)).to be(true)
end
