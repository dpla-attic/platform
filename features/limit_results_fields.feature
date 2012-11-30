Feature: Limiting result fields

  Scenario: Requesting multiple fields
    When I search with "title,description" as the value of the fields parameter
    Then I should get results with only "title,description" as fields

  Scenario: Request a single field
    When I search with "title" as the value of the fields parameter
    Then I should get results with only "title" as fields

  Scenario: Requesting an invalid field
    When I search with "invalid" as the value of the fields parameter
    Then I should get a 400 http response
