Feature: Search for items by location (UC004)
  
  In order to find content through the DPLA
  API users should be able to perform searches based on location

# Not explicitly covered in this test case
# - searching based on TGN (Getty Thesauraus of Geographic Names)
# - searching based on geonames.org linked data URIs

  Background:
    Given that I have have a valid API key
      And the default test dataset is loaded
      And the default search radius for location search is 20 miles

  Scenario: Location search by text string
    When I search for "Cambridge" in the "aggregatedCHO.spatial" field 
    Then the API should return record M

  Scenario: Location search 
    When I search for records with "aggregatedCHO.spatial.coordinates" near coordinates "42.3,-71"
    Then the API should return record M

  Scenario: Location search 
    When I search for records with "aggregatedCHO.spatial.coordinates" near coordinates "43.3,-71.1"
    Then the API should not return record M

  Scenario: Location search with expanded search radius
    When I search for records with "aggregatedCHO.spatial.coordinates" near coordinates "41,-71" with a range of 100 miles
    Then the API should return record M
  
