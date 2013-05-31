Feature: Verify the QA app is getting its API key

  In order to use the QA application
  The QA app must be able to fetch its API key
  And render its homepage successfully

  @wip
  Scenario: The QA app can render its homepage successfully
    When I visit the QA app homepage
    Then I should get http status code "200" from the QA app

