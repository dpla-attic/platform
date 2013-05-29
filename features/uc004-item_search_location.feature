Feature: Search for items by location (UC004)
  
  In order to find content through the DPLA
  API users should be able to perform searches based on location

# Not explicitly covered in this test case
# - searching based on TGN (Getty Thesauraus of Geographic Names)
# - searching based on geonames.org linked data URIs

  Background:
    Given that I have a valid API key
      And the default test dataset is loaded
      And the default search radius for location search is 20 miles

  Scenario: Location search by text string with subfield hit
    When I search for "Cambridge" in the "sourceResource.spatial" field 
    Then the API should return record M

  Scenario: Location search hit
    When I search for records with "sourceResource.spatial.coordinates" near coordinates "42.3,-71"
    Then the API should return record M

  Scenario: Location search miss
    When I search for records with "sourceResource.spatial.coordinates" near coordinates "43.3,-71.1"
    Then the API should not return record M

  Scenario: Location search hit with expanded search radius
    When I search for records with "sourceResource.spatial.coordinates" near coordinates "41,-71" with a range of 100 miles
    Then the API should return record M

  Scenario: Location search with missing range units
    When I search for records with "sourceResource.spatial.coordinates" near coordinates "41,-71" with a range of 100
    And I request a callback of jQuery_foo
    Then the API should return a valid JSON error message wrapped in my callback

  Scenario: Location bounding_box search hit
    When I search for records with "sourceResource.spatial.coordinates" inside the bounding box defined by "41.44,-74.44" and "40.25,-73.28"
    Then the API should return records L

  Scenario: Location bounding_box search miss (search for boston coordiantes misses NYC location)
    When I search for records with "sourceResource.spatial.coordinates" inside the bounding box defined by "42.93,-72.28" and "42.37,-71.11"
    Then the API should not return record L
  
