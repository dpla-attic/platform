Feature: Format API results based on request format or params

  In order to utilize search results with Javascript
  API users should be able to request search results wrapped as JSONP

  Background:
    Given that I have a valid API key
    And the default test dataset is loaded

  Scenario: JSONP wrapping is requested via "callback" query param
    When I pass callback param "boopFunction" to a search for "banana"
    Then the API response should start with "boopFunction"

  Scenario: An error is returned in valid JSON format
    When I make an empty item-search
    And do not provide an API key
    Then I should get a valid JSON response


