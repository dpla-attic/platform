Feature: Retrieve detailed information about items (UC008)

  In order to use content within the DPLA
  API users should be able to retrieve detailed information on items in the repository

  Background:
    Given that I have a valid API key
    And the default test dataset is loaded

  Scenario: Try to retrieve an item that doesn't exist in the repository
    When I request details for items with ingestion identifiers "I_DO_NOT_EXIST"
    Then the API will return a 404 http error message

  Scenario: Retrieve a single item from the repository with all fields
    When I request details for items with ingestion identifiers "aaa"
    Then the API will return the items with the document identifiers "A"
  
  Scenario: Retrieve a single item from the repository with a period in the ID field
    When I request details for items with ingestion identifiers "one.two.three"
    Then the API will return the items with the document identifiers "one.two.three"

  Scenario: Retrieve multiple items with some missing
    When I request details for items with ingestion identifiers "not_me,aaa,bbb,or_me"
    Then the API will return the items with the document identifiers "A,B"
    And items that identify errors with ids "not_me,or_me"

  Scenario: Retrieve multiple items from the repository
    When I request details for items with ingestion identifiers "aaa,bbb"
    Then the API will return the items with the document identifiers "A,B"

  Scenario: Retrieve multiple items that are all search misses
    When I request details for items with ingestion identifiers "not_me,or_me"
    And items that identify errors with ids "not_me,or_me"

