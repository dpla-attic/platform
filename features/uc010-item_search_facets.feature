Feature: Search the DPLA using facets (UC010)     

  In order to navigate the content within the DPLA
  API users should be able to perform a faceted search within the DPLA repository
               
  Background:
    Given that I have have a valid API key
    
  Scenario: Retrieve global facets
    When I make an empty search
      And request the "provider" facet
    Then the API returns the "provider.@id, provider.name" facets
      And the "provider.@id, provider.name" terms facets contains items for every unique field within the search index
      And each item within each facet contains a count of matching "terms" facet items

  Scenario: Retrieve search-specific facets
    When I search for "doppelganger"
      And request the "provider" facet
    Then the API returns items that contain the query string
      And the API returns the "provider.@id, provider.name" facets
      And the "provider.@id, provider.name" terms facets contains items for every unique field within the results set
      And each item within each facet contains a count of matching "terms" facet items

  Scenario: Retrieve facet for an invalid field
    When I make an empty search
      And request the "most_definitely_invalid" facet
    Then I should get http status code "400"

  Scenario: Retrieve simple text facet
    When I make an empty search
      And request the "aggregatedCHO.subject.name" facet
    Then the API returns the "aggregatedCHO.subject.name" facets
      And the "aggregatedCHO.subject.name" terms facets contains items for every unique field within the search index

  Scenario: Retrieve date_histogram facet
    When I make an empty search
      And request the "aggregatedCHO.date.begin" facet
    Then the API returns the "aggregatedCHO.date.begin" facets
      And the "aggregatedCHO.date.begin" date facet contains items for every unique field within the search index

  Scenario: Retrieve date_histogram facet
    When I make an empty search
      And request the "aggregatedCHO.date.end" facet
    Then the API returns the "aggregatedCHO.date.end" facets
      And the "aggregatedCHO.date.end" date facet contains items for every unique field within the search index

  Scenario: Retrieve date_histogram facet with an interval
    When I make an empty search
      And request the "aggregatedCHO.date.begin.year" facet
    Then the API returns the "aggregatedCHO.date.begin.year" facets
      And I should get http status code "200"

  Scenario: Retrieve date_histogram facet on the temporal field with an interval
    When I make an empty search
      And request the "aggregatedCHO.temporal.begin.year" facet
    Then the API returns the "aggregatedCHO.temporal.begin.year" facets
      And I should get http status code "200"

  Scenario: Retrieve date facet for date subfield 
    When I make an empty search
      And request the "aggregatedCHO.temporal.end" facet
    Then the API returns the "aggregatedCHO.temporal.end" facets
      And I should get http status code "200"

  Scenario: Retrieve geo_distance facet
    When I make an empty search
      And request the "aggregatedCHO.spatial.coordinates:42.3:-71:10mi" facet
    Then the API returns the "aggregatedCHO.spatial.coordinates" facets
      And I should get http status code "200"

  Scenario: Retrieve geo_distance facet with missing modifiers
    When I make an empty search
      And request the "aggregatedCHO.spatial.coordinates" facet
      And I should get http status code "400"

  Scenario: Retrieve simple text facet with facet_size of 'max'
    When I make an empty search
      And request the "aggregatedCHO.date.end" facet
      And request facet size of "max"
    Then the API returns the "aggregatedCHO.date.end" facets
      And I should get http status code "200"

  Scenario: Retrieve simple text facet with facet_size of 1 
    When I make an empty search
      And request the "aggregatedCHO.subject.name" facet
      And request facet size of "1"
    Then the API returns the "aggregatedCHO.subject.name" facets
      And the "aggregatedCHO.subject.name" terms facets contains the requested number of facets

  Scenario: Retrieve simple text facet with facet_size of 2
    When I make an empty search
      And request the "aggregatedCHO.subject.name" facet
      And request facet size of "2"
    Then the API returns the "aggregatedCHO.subject.name" facets
      And the "aggregatedCHO.subject.name" terms facets contains the requested number of facets

  Scenario: Retrieve date facet with facet_size of 2
    When I make an empty search
      And request the "aggregatedCHO.date.begin" facet
      And request facet size of "2"
    Then the API returns the "aggregatedCHO.date.begin" facets
      And the "aggregatedCHO.date.begin" date facets contains the requested number of facets

  #TODO: test content
  Scenario: Retrieve date_histogram facet with a custom century interval
    When I make an empty search
      And request the "aggregatedCHO.date.begin.century" facet
    Then the API returns the "aggregatedCHO.date.begin.century" facets
      And I should get http status code "200"

  #TODO: test content
  Scenario: Retrieve date_histogram facet with a custom decade interval
    When I make an empty search
      And request the "aggregatedCHO.date.begin.decade" facet
    Then the API returns the "aggregatedCHO.date.begin.decade" facets
      And I should get http status code "200"

