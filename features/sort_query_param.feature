Feature: Sort search results
  
  In order to find items through the DPLA
  API users should be able to sort search results
                                                       
  Background:
    Given that I have a valid API key
      And the default page size is 10
      And the default test dataset is loaded

  Scenario: Sort on sortable field
    When I make an empty item-search
    And sort by "id"
    And set page_size to 6
    Then the API should return sorted records 1, 2, 3, C, D, Doppel1

  Scenario: Sort on sortable field with paginated results
    When I make an empty item-search
    And sort by "id"
    And set page_size to 3
    And set page to 2
    Then the API should return sorted records C, D, Doppel1

  Scenario: Item sort on multi_field field
    When I item-search for "titlesort" in the "sourceResource.contributor" field
    And sort by "sourceResource.title"
    And set page_size to 3
    Then the API should return sorted records item-ts3, item-ts2, item-ts1

  Scenario: Collection sort on multi_field field
    When I collection-search for "titlesort" in the "description" field
    And sort by "title"
    And set page_size to 3
    Then the API should return sorted records coll-ts2, coll-ts1, coll-ts3

  Scenario: Collection sort on multi_field field with array values using script sort
    When I make an empty collection-search
    And sort by "title"
    Then I should get http status code "200"

  Scenario: Sort on multi_field field with array values using script sort
    When I make an empty item-search
    And sort by "sourceResource.title"
    Then I should get http status code "200"

  Scenario: Sort on non-sortable field
    When I make an empty item-search
    And sort by "sourceResource.description"
    Then I should get http status code "400"

  Scenario: Sort on invalid field
    When I make an empty item-search
    And sort by "dingle.hopper.x"
    Then I should get http status code "400"

  Scenario: Sort with a valid field and an invalid sort_order
    When I make an empty item-search
    And sort by "id"
    And order the sort by "invalid-dir"
    Then I should get http status code "400"

  Scenario: geo_distance sort request 
    When I make an empty item-search
    And sort by "sourceResource.spatial.coordinates"
    And sort by pin "41.3,-71"
    And set page_size to 4
    Then the API should return sorted records M, GeoDistance1, L, GeoDistance2

  Scenario: geo_distance sort request with paginated results
    When I make an empty item-search
    And sort by "sourceResource.spatial.coordinates"
    And sort by pin "41.3,-71"
    And set page_size to 2
    And set page to 2
    Then the API should return sorted records L, GeoDistance2

  Scenario: Sort on sortable field with paginated results
    When I make an empty item-search
    And sort by "id"
    And set page_size to 3
    Then the API should return sorted records 1, 2, 3

  Scenario: geo_distance type sort request without required sort_by_pin param
    When I make an empty item-search
    And sort by "sourceResource.spatial.coordinates"
    Then I should get http status code "400"

