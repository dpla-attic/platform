Feature: Search for items by keyword (UC002)
  
  In order to find items through the DPLA
  API users should be able to search for items in a specific field
                                                       
  Background:
    Given that I have have a valid API key
      And the default page size is 10
      And the default test dataset is loaded

  Scenario: Basic keyword search of title field
    When I search for "banana" in the "title" field
    Then the API should return 1 items with "banana"
    
  Scenario: Basic keyword search of description field
    When I search for "perplexed" in the "description" field
    Then the API should return 2 items with "perplexed"

  @wip
  Scenario: Basic keyword search of format field
    When I search for "text/xml" in the "format" field
    Then the API should return 1 items with "text/xml"

  Scenario: Complex field-specific search with boolean operators
    When I search for "notfound OR three" in the "description" field
    And  I search for "*doodle*" in the "subject" field
    Then the API should return record 3


