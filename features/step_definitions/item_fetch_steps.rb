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
  expected_ids = arg1.split(/,\s*/)
  body = JSON.parse(last_response.body)
  body['docs'].delete_if {|r| r['error'].present? }
  
  returned_ids = body['docs'].map { |r| r['_id'] }
  expect(returned_ids).to match_array(expected_ids)
end

Then /^items that identify errors with ids "(.*?)"$/ do |missing_docs|
  missing_ids = missing_docs.split(/,\s*/)
  body = JSON.parse(last_response.body)

  error_docs = body['docs'].select { |r| r['error'].present? }
  error_ids = error_docs.map { |d| d['id'] }
  expect(error_ids).to match_array(missing_ids)
end
