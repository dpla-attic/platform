Feature: Search the DPLA using facets (UC010)     

  In order to navigate the content within the DPLA
  API users should be able to perform a faceted search within the DPLA repository
               
  Background:
    Given that I have have a valid API key
    
  Scenario: Retrieve global facets
    When I make an empty search
      And request the "dplaContributor" facet
    Then the API returns the "dplaContributor.@id, dplaContributor.name" terms facets
      And the "dplaContributor.@id, dplaContributor.name" terms facets contains items for every unique dplaContributor within the search index
      And each item within each facet contains a count of matching items

  Scenario: Retrieve search-specific facets
    When I search for "doppelganger"
      And request the "dplaContributor" facet
    Then the API returns items that contain the query string
      And the API returns the "dplaContributor.@id, dplaContributor.name" terms facets
      And the "dplaContributor.@id, dplaContributor.name" terms facets contains items for every unique dplaContributor within the results set
      And each item within each facet contains a count of matching items


