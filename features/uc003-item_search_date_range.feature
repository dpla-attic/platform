Feature: Search for items by date range (UC003)
  
  In order to find items through the DPLA
  API users should be able to perform searches based on date ranges
            
  # The way dates are described in these tests is not meant to be an prescriptive representation of how
  # they will be represented in the repository, nor the format that will be used to query them. Also, this 
  # assumes that any 'fuzzy' dates ranges (e.g. 'circa 16th Century') will have been converted to explicit date
  # ranges (e.g. '1500 - 1599') during the ingestion process.

  Background:
    Given that I have have a valid API key
    And the default test dataset is loaded

  @wip
  Scenario: Date search after a date
    When I search the "temporal" field for records with a date after "January 1, 1950"
    Then the API should return records A, B, and C                     

  @wip
  Scenario: Date search before a date
    When I search the "temporal" field for records with a date before "December 31, 1960"
    Then the API should return records A, B, and D
    
  @wip
  Scenario: Date search after a date that overlaps a date range
    When I search the "temporal" field for records with a date after "July 15, 1955"
    Then the API should return records B and C

  @wip
  Scenario: Date search before a date that overlaps a date range
    When I search the "temporal" field for records with a date before "July 15, 1955"
    Then the API should return records A, B, D, and E

  # This demonstrates that date searches after a year should be treated as after January 1 of that year
  @wip
  Scenario: Date search after a date without specifying the month and year
    When I search the "temporal" field for records with a date after "1950"
    Then the API should return records A, B, and C
                                                                           
  # This demonstrates that date searches before a year should be treated as before December 31 of that year
  @wip
  Scenario: Date search before a date without specifying the month and year  
    When I search the "temporal" field for records with a date before "1950"
    Then the API should return records A, D, and E
    
  @wip
  Scenario: Date range search around a specific date
    When I search the "temporal" field for records with a date between "January 1, 1950" and "December 31, 1950"
    Then the API should return record "A"
    
  @wip
  Scenario: Date range search outside a date
    When I search the "temporal" field for records with a date between "January 1, 1800" and "December 31, 1850"
    Then the API should not return records A, B, C, D, nor E

  @wip
  Scenario: Date range search around a date range
    When I search the "temporal" field for records with a date between "January 1, 1955" and "December 31, 1955"
    Then the API should return record "B"
                                       
  @wip
  Scenario: Date range search within a date range
    When I search the "temporal" field for records with a date between "1210" and "1220"
    Then the API should return record "D"

  @wip
  Scenario: Date range search overlapping end of a date range
    When I search the "temporal" field for records with a date between "1975" and "1985"
    Then the API should return record "D"

  @wip
  Scenario: Date range search overlapping beginning of a date range
    When I search the "temporal" field for records with a date between "1965" and "1975"
    Then the API should return record "D"

  @wip
  Scenario: Date range search a long time ago
    When I search the "temporal" field for records with a date before "1000 BCE"
    Then the API should return record "E"

  Scenario: Date range search in the "created" field
    When I search the "created" field for records with a date between "1973-01-01" and "1973-12-31"
    Then the API should return record "F"

