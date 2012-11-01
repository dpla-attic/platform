Feature: API Http Status Code Feature
  Scenario: Successful Request
    When I raise "200"
    Then I should get http status code "200"
  
  Scenario: Bad Request Syntax
    When I raise "400"
    Then I should get http status code "400"

  Scenario: Empty/Invalid/Disabled Access Key
    When I raise "401"
    Then I should get http status code "401"

  Scenario: Resource Not Found
    When I raise "404"
    Then I should get http status code "404"

  Scenario: Not Acceptable
    When I raise "406"
    Then I should get http status code "406"

  Scenario: Too Many Requests
    When I raise "429"
    Then I should get http status code "429"

  Scenario: Internal Server Error
    When I raise "500"
    Then I should get http status code "500"

  Scenario: Service Unavailable 
    When I take the API service down for maintenance
    And I request the API
    Then I should get http status code "503"
    When I bring system back from maintenance
    When I raise "503"
    Then I should get http status code "503"
