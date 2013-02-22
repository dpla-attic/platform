Feature: Search for items by keyword (UC002)
  
  In order to find items through the DPLA
  API users should be able to search for items in a specific field
                                                       
  Background:
    Given that I have have a valid API key
      And the default page size is 10
      And the default test dataset is loaded

  Scenario: Basic keyword search of title field
    When I search for "banana" in the "aggregatedCHO.title" field
    Then the API should return 1 items with "banana"
    
  Scenario: Basic keyword search of dotted field name
    When I search for "Cambridge" in the "aggregatedCHO.spatial.city" field
    Then the API should return 1 items with "Cambridge"
    
  Scenario: Basic keyword search of description field
    When I search for "perplexed" in the "aggregatedCHO.description" field
    Then the API should return 2 items with "perplexed"

  Scenario: Complex field-specific search with boolean operators
    When I search for "notfound OR three" in the "aggregatedCHO.description" field
    And  I search for "*doodle*" in the "aggregatedCHO.subject" field
    Then the API should return record 3

  Scenario: Search date type field with invalid date query string via wildcard field
    When I search for "banana" in the "aggregatedCHO.date" field
    Then I should get http status code "200"
    

