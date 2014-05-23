Then /^the API will return a (\d+) http error message$/ do |status|
  resource_fetch(@resource, @fetch_id_string, status)
  expect(page.status_code.to_s).to eq(status)
end

When /^I request details for (.+)s with ingestion identifiers "(.*?)"$/ do |resource, arg1|
  @resource = resource
  @fetch_id_string = arg1
end

Then /^the API will return the (.+)s with the document identifiers "(.*?)"$/ do |resource, arg1|
  expect(resource).to eq @resource
  expected_ids = arg1.split(/,\s*/)

  body = resource_fetch(resource, @fetch_id_string)
  body['docs'].delete_if {|r| r['error'].present? }
  
  returned_ids = body['docs'].map { |r| r['_id'] }
  expect(returned_ids).to match_array(expected_ids)
end

Then /^(.+)s that identify errors with ids "(.*?)"$/ do |resource, missing_docs|
  missing_ids = missing_docs.split(/,\s*/)
  body = resource_fetch(resource, @fetch_id_string)

  error_docs = body['docs'].select { |r| r['error'].present? }
  error_ids = error_docs.map { |d| d['id'] }
  expect(error_ids).to match_array(missing_ids)
end

When(/^I fetch (\w+)s with ids "(.*?)" without an API key$/) do |resource, ids|
  # This is needed because we don't have good modulatiry in our steps for fetches and the API key omission
  @resource = resource
  @fetch_id_string = ids
  expected_http_code = @params.key?('api_key') ? 200 : 401

  resource_fetch(resource, @fetch_id_string, expected_http_code)
end
