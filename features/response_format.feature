Feature: Format API results based on request format or params

  In order to utilize search results with Javascript
  API users should be able to request search results wrapped as JSONP

  Background:
    Given that I have a valid API key
    And the default test dataset is loaded

  Scenario: Non-wrapped response is valid JSON
    When I make an empty item-search
    Then I should get a valid JSON response

  Scenario: JSONP-wrapped response is valid JSON
    When I pass callback param "boop" to a search for "banana"
    Then the API response should start with "boop"
    And I should get a valid JSON response

  Scenario: JSONP-wrapped response is wrapped by callback value
    When I pass callback param "boop" to a search for "banana"
    Then the API response should start with "boop"
    
  Scenario: An error is returned in valid JSON format
    When I make an empty item-search
    And do not provide an API key
    Then I should get a valid JSON response

  Scenario: JSONP-wrapped error response is valid JSON
    When I pass callback param "boop" to a search for "banana"
    And do not provide an API key
    And I make an empty item-search
    And I should get a valid JSON response

  Scenario: Search endpoint times out
    When I make an empty item-search and the search endpoint times out
    Then I should get http status code "503"
    And I should get a valid JSON response

