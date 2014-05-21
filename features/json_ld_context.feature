Feature: JSON-LD context handling

  Background:
    Given that I have a valid API key

  Scenario: Fetch 'item' context document
    When I request the JSON-LD context document for the "item" resource
    Then the API should return JSON that matches the JSON from disk
    
  Scenario: Fetch 'collection' context document
    When I request the JSON-LD context document for the "collection" resource
    Then the API should return JSON that matches the JSON from disk
    
