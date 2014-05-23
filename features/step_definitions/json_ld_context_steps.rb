When(/^I request the JSON\-LD context document for the "(.*?)" resource$/) do |resource|
  @json_ld_resource = resource
  json_ld_context_fetch(resource)
end

Then(/^the API should return JSON that matches the JSON from disk$/) do
  if page.status_code != 200
    raise Exception, "API returned unexpected HTTP 200: #{page.status_code}"
  end

  expect(page.source).to eq V1::JsonLd.context_for @json_ld_resource
end
