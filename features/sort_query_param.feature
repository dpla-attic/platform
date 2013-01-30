Feature: Sort search results
  
  In order to find items through the DPLA
  API users should be able to sort search results
                                                       
  Background:
    Given that I have have a valid API key
      And the default page size is 10
      And the default test dataset is loaded

  Scenario: Sort on sortable field
    When I make an empty search
    And sort by "id"
    Then I should get http status code "200"

  Scenario: Sort on analyzed field using script-type sort
    When I make an empty search
    And sort by "title"
    Then I should get http status code "200"

  Scenario: Sort on not_analyzed field with array values using script-type sort
    When I make an empty search
    And sort by "subject.name"
    Then I should get http status code "200"

  Scenario: Sort on non-sortable field
    When I make an empty search
    And sort by "description"
    Then I should get http status code "400"

  Scenario: geo_distance type sort request with required sort_by_pin param
    When I make an empty search
    And sort by "spatial.coordinates"
    And sort by pin "41.3,-71"
    Then I should get http status code "200"

  Scenario: geo_distance type sort request without required sort_by_pin param
    When I make an empty search
    And sort by "spatial.coordinates"
    Then I should get http status code "400"
