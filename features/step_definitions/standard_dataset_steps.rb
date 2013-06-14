Given /^the dataset exists$/ do
  V1::SearchEngine::dataset_files.each do |file|
    expect(File.exist?(file)).to be_true
  end
end

When /^I load the test dataset$/ do
  @json = load_dataset rescue $!
end

Then /^I should not get a dataset error$/ do
  expect(@json.is_a?(JSON::ParserError) ).to be_false
end

Given /^there are (\d+) items with "(.*?)" in the "(.*?)" field$/ do |arg1, target, field|
  docs = load_dataset

  names = field.split('.')
  count = 0
  docs.each do |doc|
    # for each doc, traverse hash and increment count if end node contained target
    names.each do |name|
      doc = doc[name] rescue nil
      count += 1 if doc =~ /#{target}/
    end
  end

  expect(count.to_s).to eq(arg1)
end

Given /^there is a metadata record "(.*?)" with "(.*?)" in the "(.*?)" field$/ do |id, expected, field|
  docs = load_dataset

  doc = docs.detect {|doc| doc['_id'] == id}

  #traverse hash tree
  names = field.split('.')
  names.each do |name|
    doc = doc[name]
  end

  expect(doc).to eq expected
end
