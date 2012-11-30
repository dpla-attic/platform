Then /^the API will return a (\d+) http error message$/ do |status|
  expect(last_response.status).to eq(status.to_i)
end

Then /^include all the fields available in the repository for that record$/ do
pending # express the regexp above with the code you wish you had
end

When /^I request details for items with ingestion identifiers "(.*?)"$/ do |arg1|
  get "/api/v1/items/#{arg1}"
end

Then /^the API will return the items with the document identifiers "(.*?)"$/ do |arg1|
  body = JSON.parse(last_response.body)
  expected_ids = arg1.split(',')
  body.delete_if{ |r| r['error'].present? }
  expect(body.count).to eq(expected_ids.count)
  docs = body.map { |r| r['doc'] }
  returned_ids = docs.map { |d| d['_id'] } 
  expect(returned_ids - expected_ids).to eq([])
end

Then /^items that identify errors with ids "(.*?)"$/ do |missing_docs|
  body = JSON.parse(last_response.body)
  missing_ids = missing_docs.split(',')
  error_docs = []
  body.each { |r| error_docs << r if r['error'].present? }
  error_ids = error_docs.map { |d| d['id'] }
  expect(error_ids - missing_ids).to eq([])
end
