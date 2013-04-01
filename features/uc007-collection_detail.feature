Feature: Retrieve detailed information about collections (UC007)

  In order to find content through the DPLA
  API users should be able to retrieve information about collections

  Background:
    Given that I have a valid API key
    And the default test dataset is loaded

  Scenario: Try to retrieve a collection that doesn't exist in the repository
    When I request details for collections with ingestion identifiers "I_DO_NOT_EXIST"
    Then the API will return a 404 http error message

  Scenario: Retrieve a single collection from the repository with all fields
    When I request details for collections with ingestion identifiers "coll1"
    Then the API will return the collections with the document identifiers "private-coll1"

  Scenario: Retrieve multiple collections from the repository
    When I request details for collections with ingestion identifiers "coll1,coll2"
    Then the API will return the collections with the document identifiers "private-coll1,private-coll2"

  Scenario: Retrieve multiple collections with some missing
    When I request details for collections with ingestion identifiers "not_me,coll1,coll2,or_me"
    Then the API will return the collections with the document identifiers "private-coll1,private-coll2"
    And collections that identify errors with ids "not_me,or_me"
