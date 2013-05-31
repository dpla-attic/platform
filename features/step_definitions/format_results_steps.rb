When /^I pass callback param "(.*?)" to a search for "(.*?)"$/ do |callback, keyword|
  @params.merge!({ 'q' => keyword, 'callback' => callback })
end

Then /^the API response should start with "(.*?)"$/ do |callback|
  item_query(@params)
  expect(page.source).to match /^#{callback}\(/
end
