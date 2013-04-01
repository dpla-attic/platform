Feature: Limiting result fields

  Background:
    Given that I have a valid API key
      And the default test dataset is loaded

  Scenario: Requesting multiple fields
    When I search with "sourceResource.title, sourceResource.description" as the value of the fields parameter
    Then I should get results with only "sourceResource.title, sourceResource.description" as fields

  Scenario: Request a single field
    When I search with "sourceResource.title" as the value of the fields parameter
    Then I should get results with only "sourceResource.title" as fields

  Scenario: Requesting an invalid field
    When I search with "most_definitely_invalid" as the value of the fields parameter
    Then I should get http status code "400"
