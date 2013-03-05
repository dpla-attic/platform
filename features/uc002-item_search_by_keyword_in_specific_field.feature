Feature: Search for items by keyword (UC002)
  
  In order to find items through the DPLA
  API users should be able to search for items in a specific field
                                                       
  Background:
    Given that I have have a valid API key
      And the default page size is 10
      And the default test dataset is loaded

  Scenario: Basic keyword search of title field
    When I item-search for "banana" in the "aggregatedCHO.title" field
    Then the API should return record 1
    
  Scenario: Basic keyword search with case-insensitive match
    When I item-search for "cambridge" in the "aggregatedCHO.spatial.city" field
    Then the API should return record M
    
  Scenario: Basic keyword search of analyzed multi_field field with multiple query terms
    When I item-search for "perplexed doodle" in the "aggregatedCHO.subject.name" field
    Then the API should return record 3
    
  Scenario: Basic keyword search of analyzed multi_field field with multiple query terms
    When I item-search for "perplexed doodle" in the "aggregatedCHO.subject.name" field
    Then the API should return record 3
    
  Scenario: Phrase search of analyzed multi_field field that is not a match
    When I item-search for the phrase "perplexed doodle" in the "aggregatedCHO.subject.name" field
    Then the API should return no records
    
  Scenario: Phrase search of analyzed multi_field field, exact match
    When I item-search for the phrase "perplexed subject3 doodle" in the "aggregatedCHO.subject.name" field
    Then the API should return record 3
    
  Scenario: Phrase search of analyzed multi_field field, partial match
    When I item-search for the phrase "perplexed subject3" in the "aggregatedCHO.subject.name" field
    Then the API should return record 3
    
  Scenario: Phrase search of analyzed multi_field field that is not a phrase match, only a boolean match
    When I item-search for the phrase "doodle subject3 perplexed" in the "aggregatedCHO.subject.name" field
    Then the API should return no records

  Scenario: Basic search of analyzed multi_field field with multiple boolean operators
    When I item-search for "perplexed AND subject3 AND doodle" in the "aggregatedCHO.subject.name" field
    Then the API should return record 3

  Scenario: Basic keyword search of description field
    When I item-search for "perplexed" in the "aggregatedCHO.description" field
    Then the API should return record 2, 3

  Scenario: Complex field-specific search with boolean operators
    When I item-search for "notfound OR three" in the "aggregatedCHO.description" field
    And  I item-search for "doodle" in the "aggregatedCHO.subject" field
    Then the API should return record 3

  Scenario: Complex field-specific search with excluded and included fields
    When I item-search for "+banana -apple" in the "aggregatedCHO.title" field
    Then the API should return record 1

  Scenario: Search date type field with invalid date query string via wildcard field
    When I item-search for "banana" in the "aggregatedCHO.date" field
    Then I should get http status code "200"
    
  Scenario: Basic keyword item-search of title field that excludes hits outside the 'item' resource
    When I item-search for "orange" in the "aggregatedCHO.title" field
    Then the API should return no records


