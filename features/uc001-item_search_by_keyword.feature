Feature: Search for items by keyword (UC001)
  
  In order to find items through the DPLA
  API users should be able to search for items using free text search
                                                       
  Background:
    Given that I have have a valid API key
      And the default test dataset is loaded
  
  Scenario: Free text search with hits on title
    When I search for "banana"
    Then the API should return 1 items with "banana"
    
  Scenario: Free text search with hits on the description
    When I search for "perplexed"
    Then the API should return 2 items with "perplexed"

  @wip
  Scenario: Keyword search matching text in 'spatial' field
    When I search for 'Cambridge' without specifying a specific field to search in
    Then the API should return record M
  
