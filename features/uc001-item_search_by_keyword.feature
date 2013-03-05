Feature: Search for items by keyword (UC001)
  
  In order to find content through the DPLA
  API users should be able to search for items using free text search
                                                       
  Background:
    Given that I have have a valid API key
      And the default test dataset is loaded
  
  Scenario: Free text item search with hits on the title
    When I item-search for "banana"
    Then the API should return 1 items with "banana"
    
  Scenario: Free text item search with hits on the description
    When I item-search for "perplexed"
    Then the API should return 2 items with "perplexed"

  Scenario: Free text item-search that omits hits outside the 'item' resource
    When I item-search for "apple"
    Then the API should return no records

  
