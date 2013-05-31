Feature: Search the DPLA using filtered facets (UC010)

  In order to navigate the content within the DPLA
  API users should be able to perform a faceted search within the DPLA repository
               
  Background:
    Given that I have a valid API key
    And the default test dataset is loaded

  Scenario: Filter facets with a single bare word search with matching case
    When I item-search for "Cookie" in the "sourceResource.subject.name" field
      And request the "sourceResource.subject.name" facet
      And filter facets on "sourceResource.subject.name"
    Then the API returns facets with the filtered values "Cookie"

  Scenario: Filter facets with a single bare word search with non-matching case
    When I item-search for "COOKIE" in the "sourceResource.subject.name" field
      And request the "sourceResource.subject.name" facet
      And filter facets on "sourceResource.subject.name"
    Then the API returns facets with the filtered values "COOKIE"

  Scenario: Filter facets with multiple word search with default AND behavior
    When I item-search for "west mountain" in the "sourceResource.subject.name" field
      And request the "sourceResource.subject.name" facet
      And filter facets on "sourceResource.subject.name"
    Then the API returns facets with the filtered values "mountain west"

  Scenario: Filter facets with multiple word search with explicit OR behavior
    When I item-search for "mountain OR west" in the "sourceResource.subject.name" field
      And request the "sourceResource.subject.name" facet
      And filter facets on "sourceResource.subject.name"
    Then the API returns facets with the filtered values "mountain west|splash mountain"

  Scenario: Filter facets with a phrase search
    When I item-search for the phrase "Old Man" in the "sourceResource.subject.name" field
      And request the "sourceResource.subject.name" facet
      And filter facets on "sourceResource.subject.name"
    Then the API returns facets with the filtered values "old man winter"

  Scenario: Filter facets with single word wildcard search
    When I item-search for "*berry" in the "sourceResource.subject.name" field
      And request the "sourceResource.subject.name" facet
      And filter facets on "sourceResource.subject.name"
    Then the API returns facets with the filtered values "blueberry|cranberry"

  Scenario: Do not filter facets with a single bare word search
    When I item-search for "Cookie" in the "sourceResource.subject.name" field
      And request the "sourceResource.subject.name" facet
    Then the API returns facets with the filtered values "cookie|mountain west"

