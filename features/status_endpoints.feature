Feature: Status endpoints
  
  In order to monitor services the DPLA depends upon
  The API should provide status data for those services
                                                       
  Background:
    Given that I have a valid monitoring API key
      And the default page size is 10
      And the default test dataset is loaded

  Scenario: Repository status OK
    When I fetch the "repository" status URL
    Then I should get http status code "200"

