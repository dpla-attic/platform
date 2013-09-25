Feature: Search for items by dates (UC003)
  
  In order to find items through the DPLA
  API users should be able to perform searches based on dates that have implicit wildcards
            
  Background:
    Given that I have a valid API key
    And the default test dataset is loaded

  Scenario: Date search for $year
    When I item-search for "2000" in the "sourceResource.date.begin" field
    Then the API should return records 3

  Scenario: Date search for $year
    When I item-search for "1973" in the "sourceResource.date.end" field
    Then the API should return records DATERANGE1, DATERANGE2, DATERANGE3, DATERANJ4, F

  Scenario: Date search for $year-$month
    When I item-search for "1973-04" in the "sourceResource.date.end" field
    Then the API should return records DATERANGE1, F

  Scenario: Date search for $year-$month-$day
    When I item-search for "1973-04-19" in the "sourceResource.date.end" field
    Then the API should return records F

  Scenario: Date search for $year
    When I item-search for "1988" in the "sourceResource.temporal.begin" field
    Then the API should return records Doppel1, Doppel2, F

  Scenario: Date search for $year
    When I item-search for "1988" in the "sourceResource.temporal.end" field
    Then the API should return records Doppel1, Doppel2, F

  Scenario: Date search for $year-$month
    When I item-search for "1988-03" in the "sourceResource.temporal.end" field
    Then the API should return records Doppel1, Doppel2

  Scenario: Date search for invalid date
    When I item-search for "?year=1969" in the "sourceResource.date.begin" field
    Then the API should not hit the search engine
    Then I should get http status code "400"

