When /^I search for "(.*?)" in the "(.*?)" field$/ do |keyword, field|
  params = { field => keyword }
  visit("/api/v1/items?#{ params.to_param }")
  @json = JSON.parse(page.source)
end

