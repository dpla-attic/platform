Feature: Format API results based on request format or params

  In order to utilize search results with Javascript
  API users should be able to request search results wrapped as JSONP

  Background:
    Given that I have a valid API key
    And the default test dataset is loaded

  Scenario: Request with no JSONP callback
    When I make an empty item-search
    Then I should get http status code "200"
    And I should get a valid JSON response

  Scenario: Request with a JSONP callback
    When I pass callback param "boop" to a search for "banana"
    Then the API response should start with "boop"
    And I should get a valid JSON response
    
  Scenario: Request made without an API key with no JSONP callback
    When I make an empty item-search
    And do not provide an API key
    Then I should get http status code "401"
    And I should get a valid JSON response

  Scenario: Request made without an API key with a JSONP callback
    When I pass callback param "boop" to a search for "banana"
    And do not provide an API key
    Then the API response should start with "boop"
    And I should get http status code "401"
    And I should get a valid JSON response

  Scenario: Request made with an unrecognized query field
    When I item-search for "banana" in the "not_a_real_field" field
    Then I should get http status code "400"
    And I should get a valid JSON response

  Scenario: Request made with an unrecognized query field with a JSONP callback
    When I pass callback param "boop" to a search for "banana"
    When I item-search for "orange" in the "not_a_real_field" field
    Then the API response should start with "boop"
    Then I should get http status code "400"
    And I should get a valid JSON response

  Scenario: Request made with an unrecognized facets field
    When I item-search for "banana"
    And request the "not_a_real_facet" facet
    Then I should get http status code "400"
    And I should get a valid JSON response

  Scenario: Request made with an unrecognized facets field with a JSONP callback
    When I pass callback param "boop" to a search for "banana"
    And request the "not_a_real_facet" facet
    Then the API response should start with "boop"
    Then I should get http status code "400"
    And I should get a valid JSON response

  Scenario: Request made with an unrecognized "fields" value
    When I item-search with "not_a_real_field" as the value of the fields parameter
    Then I should get http status code "400"
    And I should get a valid JSON response

  Scenario: Search endpoint times out
    When I make an empty item-search and the search endpoint times out
    Then I should get http status code "503"
    And I should get a valid JSON response

  Scenario: Search endpoint times out with a JSONP callback
    When I pass callback param "boop" to a search for "banana"
    And I make an empty item-search and the search endpoint times out
    Then the API response should start with "boop"
    Then I should get http status code "503"
    And I should get a valid JSON response

  Scenario: Retrieve a single item from the repository with 
    When do not provide an API key
    When I fetch items with ids "aaa" without an API key
    And I should get a valid JSON response

