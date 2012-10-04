When /^I search for "(.*?)"$/ do |keyword|
  params = { 'q' => keyword }
  visit("/api/v1/items?#{ params.to_param }")
  @json = JSON.parse(page.source)
end

Then /^the API should return (\d+) items with "(.*?)"$/ do |count, keyword|
  expect(@json).to have(count).items
  @json.each_with_index do |result, idx|
    Rails.logger.debug "RESULT: #{idx}: #{result.inspect}"
    expect(result).to have_content(keyword)
  end
end

