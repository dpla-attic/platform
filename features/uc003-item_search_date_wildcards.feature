Feature: Search for items by dates (UC003)
  
  In order to find items through the DPLA
  API users should be able to perform searches based on dates that have implicit wildcards
            
  Background:
    Given that I have a valid API key
    And the default test dataset is loaded

  Scenario: Date search for $year
    When I item-search for "1973" in the "sourceResource.date.end" field
    Then the API should return records DATERANGE1, DATERANGE2, DATERANGE3, DATERANJ4, F

  Scenario: Date search for $year-$month
    When I item-search for "1973-04" in the "sourceResource.date.end" field
    Then the API should return records DATERANGE1, F

  Scenario: Date search for $year-$month-$month
    When I item-search for "1973-04-19" in the "sourceResource.date.end" field
    Then the API should return records F
