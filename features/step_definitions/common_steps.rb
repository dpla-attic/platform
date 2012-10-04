Given /^that I have have a valid API key$/ do
#  pending
end

Given /^the default page size is (\d+)$/ do |arg1|
  expect(V1::Config::DEFAULT_PAGE_SIZE ).to eq 10  #TODO: Not 100% expressive/useful here
end

Given /^the default test dataset is loaded$/ do
  expect(Tire.index('dpla').exists?).to be_true
end
