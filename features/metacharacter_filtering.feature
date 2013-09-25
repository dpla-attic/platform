Feature: Search for items by keyword with meta-characters in the query string
  
  In order to find items through the DPLA
  API users should be able to search on meta-characters
                                                       
  Background:
    Given that I have a valid API key
      And the default test dataset is loaded

  Scenario: Basic keyword search with parseable meta-characters
    When I item-search for "test (lol)"
    Then the API should return record MC1    

  Scenario: Basic keyword search with un-parseable meta-characters
    When I item-search for "test (lol"
    Then I should get http status code "200"
    And the API should return record MC1    

  Scenario: Basic keyword search with un-parseable meta-characters
    When I item-search for "&&test{"
    Then I should get http status code "200"

  Scenario: Basic keyword search with crazy multiple un-parseable meta-characters everywhere
    When I item-search for "}?harv[a:z]("
    Then the API should return record item-meta2

  Scenario: Basic keyword search with embedded double-quote
    When I item-search for '2 pieces, 3 3/4" x 7'
    Then I should get http status code "200"

  Scenario: Basic keyword search with embedded double-quote wrapped in outer double-quotes
    When I item-search for '"2 pieces, 3 3/4" x 7"'
    Then I should get http status code "200"

  Scenario: Basic keyword search wrapped in outer double-quotes
    When I item-search for '"2 pieces, 3 x 7"'
    Then I should get http status code "200"

  Scenario: Basic keyword search with embedded double-quote wrapped in outer double-quotes
    When I item-search for '"1 1/2" by 3 1/2""'
    Then the API should return record item-meta1

  Scenario: Field search with two double-quote wrapped terms joined with 'AND'
    When I item-search for ""Toast" AND "Bread Truck Fires"" in the "sourceResource.subject.name" field
    Then the API should return record MSN1


