Given /^the default search radius for location search is (\d+) miles$/ do |arg1|
  expect(V1::Item::DEFAULT_SPATIAL_DISTANCE).to eq '20mi'
end

When /^I search for records with location near coordinates "(.*?)"( with a range of (\d+) miles)?$/ do |lat_long, junk, distance|
  params = {'spatial.coordinates' => lat_long}
  params['spatial.distance'] = distance + 'mi' if distance

  @json = item_query_to_json(params)
end

