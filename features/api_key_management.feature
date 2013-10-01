Feature: API Key Management through API endpoints

  In order to create a new API key or retrieve an existing one
  API users can perform those actions via unsecured API endpoints

  Scenario: Make a GET request against the API key creation endpoint instead of HTTP POST
    When I request a new api key for "cuketest-1@dp.la" using GET
    Then I should get http status code "500"
    And I should get a JSON message containing "http://dp.la/info/developers/codex/policies/#get-a-key"

  Scenario: Request a new API key
    When I request a new api key for "cuketest-1@dp.la" using POST
    Then I should get http status code "201"

