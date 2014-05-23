Feature: JSON-LD context handling

  Background:

  Scenario: Fetch 'item' context document
    When I request the JSON-LD context document for the "item" resource
    Then I should get http status code "200"
    And I should get a valid JSON response

  Scenario: Fetch 'item' context document
    When I request the JSON-LD context document for the "item" resource
    Then I should get http status code "200"
    And I should get a valid JSON response
    Then the API should return JSON that matches the JSON from disk
    
  Scenario: Fetch 'collection' context document
    When I request the JSON-LD context document for the "collection" resource
    Then I should get http status code "200"
    And I should get a valid JSON response
    Then the API should return JSON that matches the JSON from disk
    
