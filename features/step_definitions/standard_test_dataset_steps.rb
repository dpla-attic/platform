Given /^the dataset exists$/ do
  expect(File.exist?V1::StandardDataset::ITEMS_JSON_FILE).to be_true
end

When /^I load the test dataset$/ do
  @json = load_dataset
end

Then /^I should not get a dataset error$/ do
  expect {
    JSON.parse(@json)
  }.to_not raise_error(JSON::ParserError)
end

Given /^there are (\d+) items with "(.*?)" in the "(.*?)" field$/ do |arg1, target, field|
  docs = JSON.parse(load_dataset)

  names = field.split('.')
  count = 0
  docs.each do |doc|
    # for each doc, traverse hash and add to counter if end node contained
    names.each do |name|
      doc = doc[name]
      count += 1 if doc =~ /#{target}/
    end

  end

  expect(count.to_s).to eq(arg1)
end

Given /^there is a metadata record "(.*?)" with "(.*?)" in the "(.*?)" field$/ do |id, expected, field|
  docs = JSON.parse(load_dataset)
  doc = docs.detect {|doc| doc['_id'] == id}

  #traverse hash tree
  names = field.split('.')
  names.each do |name|
    doc = doc[name]
  end

  expect(doc).to eq expected
end
