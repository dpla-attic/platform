Feature: Search for items by keyword with/without valid API key (UC001)

  In order to find items through the DPLA
  Search requests must supply a valid API key

  Scenario: Free text search without an API key
    When I make an empty item-search
    And do not provide an API key
    Then I should get http status code "401"

  Scenario: Free text search with an invalid API key
    When I make an empty item-search
    And provide a invalid API key
    Then I should get http status code "401"

  Scenario: Free text search with an valid but disabled API key
    When I make an empty item-search
    And provide a disabled API key
    Then I should get http status code "401"
    
  Scenario: Free text search with an valid and not-disabled key
    When I make an empty item-search
    And provide a valid API key
    Then I should get http status code "200"

  Scenario: Free text search with an valid and not-disabled key
    When I make an empty item-search
    And provide a valid API key
    Then I should get http status code "200"

