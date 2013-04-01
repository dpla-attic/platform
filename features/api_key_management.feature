Feature: API Key Management through API endpoints

  In order to create a new API key or retrieve an existing one
  API users can perform those actions via unsecured API endpoints

  @api_key_generation @wip
  Scenario: Create a new API key for a new user
    When I request a new api key for "cuketest-1@dp.la"
    Then a new key is created but not emailed to me yet
