Feature: Search the DPLA using facets (UC010)     

  In order to navigate the content within the DPLA
  API users should be able to perform a faceted search within the DPLA repository
               
  Background:
    Given that I have a valid API key
    
  Scenario: Retrieve global facets
    When I make an empty item-search
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
    When I make an empty item-search
      And request the "most_definitely_invalid" facet
    Then I should get http status code "400"

  Scenario: Retrieve facet for an valid field that is not facetable?
    When I make an empty item-search
      And request the "sourceResource.description" facet
    Then I should get http status code "400"

  Scenario: Retrieve simple text facet
    When I make an empty item-search
      And request the "sourceResource.subject.name" facet
    Then the API returns the "sourceResource.subject.name" facets
      And the "sourceResource.subject.name" terms facets contains items for every unique field within the search index

  Scenario: Retrieve date_histogram facet with default interval (day)
    When I make an empty item-search
      And request the "sourceResource.date.begin" facet
    Then the API returns the "sourceResource.date.begin" facets
      And the "sourceResource.date.begin" date facet contains items for every unique value within the search index

  Scenario: Retrieve date_histogram facet with default interval (day)
    When I make an empty item-search
      And request the "sourceResource.date.end" facet
    Then the API returns the "sourceResource.date.end" facets
      And the "sourceResource.date.end" date facet contains items for every unique value within the search index

  Scenario: Retrieve date_histogram facet with an interval
    When I make an empty item-search
      And request the "sourceResource.date.begin.year" facet
    Then the API returns the "sourceResource.date.begin.year" facets
      And I should get http status code "200"

  Scenario: Retrieve date_histogram facet on the temporal field with an interval
    When I make an empty item-search
      And request the "sourceResource.temporal.begin.year" facet
    Then the API returns the "sourceResource.temporal.begin.year" facets
      And I should get http status code "200"

  Scenario: Retrieve date facet for date subfield 
    When I make an empty item-search
      And request the "sourceResource.temporal.end" facet
    Then the API returns the "sourceResource.temporal.end" facets
      And I should get http status code "200"

  Scenario: Retrieve geo_distance facet
    When I make an empty item-search
      And request the "sourceResource.spatial.coordinates:42.3:-71:10mi" facet
    Then the API returns the "sourceResource.spatial.coordinates" facets
      And I should get http status code "200"

  Scenario: Retrieve geo_distance facet with missing modifiers
    When I make an empty item-search
      And request the "sourceResource.spatial.coordinates" facet
      And I should get http status code "400"

  Scenario: Retrieve simple text facet with facet_size of 'max'
    When I make an empty item-search
      And request the "sourceResource.date.end" facet
      And request facet size of "max"
    Then the API returns the "sourceResource.date.end" facets
      And I should get http status code "200"

  Scenario: Retrieve simple text facet with facet_size of 1 
    When I make an empty item-search
      And request the "sourceResource.subject.name" facet
      And request facet size of "1"
    Then the API returns the "sourceResource.subject.name" facets
      And the "sourceResource.subject.name" terms facets contains the requested number of facets

  Scenario: Retrieve simple text facet with facet_size of 2
    When I make an empty item-search
      And request the "sourceResource.subject.name" facet
      And request facet size of "2"
    Then the API returns the "sourceResource.subject.name" facets
      And the "sourceResource.subject.name" terms facets contains the requested number of facets

  Scenario: Retrieve date facet with facet_size of 2
    When I make an empty item-search
      And request the "sourceResource.date.begin" facet
      And request facet size of "2"
    Then the API returns the "sourceResource.date.begin" facets
      And the "sourceResource.date.begin" date facets contains the requested number of facets

  #TODO: test content
  Scenario: Retrieve date_histogram facet with a custom century interval
    When I make an empty item-search
      And request the "sourceResource.date.begin.century" facet
    Then the API returns the "sourceResource.date.begin.century" facets
      And I should get http status code "200"

  #TODO: test content
  Scenario: Retrieve date_histogram facet with a custom decade interval
    When I make an empty item-search
      And request the "sourceResource.date.begin.decade" facet
    Then the API returns the "sourceResource.date.begin.decade" facets
      And I should get http status code "200"

  Scenario: Retrieve date_histogram facet with day interval with default facet sorting
    When I make an empty item-search
      And request the "sourceResource.date.begin" facet
    Then the API returns the "sourceResource.date.begin" facets
    And the facets should be sorted by count descending

