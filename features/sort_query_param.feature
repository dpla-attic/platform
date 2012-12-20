Feature: Sort search results
  
  In order to find items through the DPLA
  API users should be able to sort search results
                                                       
  Background:
    Given that I have have a valid API key
      And the default page size is 10
      And the default test dataset is loaded

  Scenario: Valid sort request
    When I make an empty search
    And sort by "id"
    Then I should get http status code "200"

  Scenario: Invalid sort request
    When I make an empty search
    And sort by "description"
    Then I should get http status code "400"
