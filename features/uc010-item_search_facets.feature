Feature: Search the DPLA using facets (UC010)     

  In order to navigate the content within the DPLA
  API users should be able to perform a faceted search within the DPLA repository
               
  Background:
    Given that I have have a valid API key
    
  Scenario: Retrieve global facets
    When I make an empty search
      And request the "dplaContributor" facet
    Then the API returns the "dplaContributor.@id, dplaContributor.name" facets
      And the "dplaContributor.@id, dplaContributor.name" terms facets contains items for every unique field within the search index
      And each item within each facet contains a count of matching "terms" facet items

  Scenario: Retrieve search-specific facets
    When I search for "doppelganger"
      And request the "dplaContributor" facet
    Then the API returns items that contain the query string
      And the API returns the "dplaContributor.@id, dplaContributor.name" facets
      And the "dplaContributor.@id, dplaContributor.name" terms facets contains items for every unique field within the results set
      And each item within each facet contains a count of matching "terms" facet items

  Scenario: Retrieve facet for an invalid field
    When I make an empty search
      And request the "most_definitely_invalid" facet
    Then I should get http status code "400"

  Scenario: Retrieve simple text facet
    When I make an empty search
      And request the "subject.name" facet
    Then the API returns the "subject.name" facets
      And the "subject.name" terms facets contains items for every unique field within the search index

  Scenario: Retrieve date facet
    When I make an empty search
      And request the "created.start" facet
    Then the API returns the "created.start" facets
      And the "created.start" date facet contains items for every unique field within the search index

  Scenario: Retrieve date facet with an interval
    When I make an empty search
      And request the "created.start.year" facet
    Then the API returns the "created.start.year" facets
      And I should get http status code "200"

  Scenario: Retrieve date facet on the temporal field with an interval
    When I make an empty search
      And request the "temporal.start.year" facet
    Then the API returns the "temporal.start.year" facets
      And I should get http status code "200"

  Scenario: Retrieve date facet for date subfield 
    When I make an empty search
      And request the "temporal.end" facet
    Then the API returns the "temporal.end" facets
      And I should get http status code "200"

  Scenario: Retrieve geo_distance facet
    When I make an empty search
      And request the "spatial.coordinates:42.3:-71:10mi" facet
    Then the API returns the "spatial.coordinates" facets
      And I should get http status code "200"

  Scenario: Retrieve geo_distance facet with missing modifiers
    When I make an empty search
      And request the "spatial.coordinates" facet
      And I should get http status code "400"

  Scenario: Retrieve simple text facet with facet_size of 'max'
    When I make an empty search
      And request the "created.end" facet
      And request facet size of "max"
    Then the API returns the "created.end" facets
      And I should get http status code "200"

  Scenario: Retrieve simple text facet with facet_size of 1 
    When I make an empty search
      And request the "subject.name" facet
      And request facet size of "1"
    Then the API returns the "subject.name" facets
      And the "subject.name" terms facets contains the requested number of facets

  Scenario: Retrieve simple text facet with facet_size of 2
    When I make an empty search
      And request the "subject.name" facet
      And request facet size of "2"
    Then the API returns the "subject.name" facets
      And the "subject.name" terms facets contains the requested number of facets

  Scenario: Retrieve date facet with facet_size of 2
    When I make an empty search
      And request the "created.start" facet
      And request facet size of "2"
    Then the API returns the "created.start" facets
      And the "created.start" date facets contains the requested number of facets
