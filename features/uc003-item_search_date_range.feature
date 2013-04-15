Feature: Search for items by date range (UC003)
  
  In order to find items through the DPLA
  API users should be able to perform searches based on date ranges
            
  Background:
    Given that I have a valid API key
    And the default test dataset is loaded

  Scenario: Date search after a date
    When I search the "sourceResource.temporal" field for records with a date after "1950-01-01"
    Then the API should return records A, B, C, F, Doppel1, Doppel2

  Scenario: Date search before a date
    When I search the "sourceResource.temporal" field for records with a date before "1960-12-31"
    Then the API should return records A, B, D

  Scenario: Date search after a date that overlaps a date range
    When I search the "sourceResource.temporal" field for records with a date after "1955-07-15"
    Then the API should return records B, C, F, Doppel1, Doppel2

  Scenario: Date search before a date that overlaps a date range
    When I search the "sourceResource.temporal" field for records with a date before "1955-07-15"
    Then the API should return records A, B, D

  # This demonstrates that date searches after a year should be treated as after January 1 of that year
  Scenario: Date search after a date without specifying the month and year
    When I search the "sourceResource.temporal" field for records with a date after "1950"
    Then the API should return records A, B, C, F, Doppel1, Doppel2
                                                                           
  # This demonstrates that date searches before a year should be treated as before January 1 of the next year
  Scenario: Date search before a date without specifying the month and year  
    When I search the "sourceResource.temporal" field for records with a date before "1951"
    Then the API should return records A, D
    
  Scenario: Date range search around a specific date
    When I search the "sourceResource.temporal" field for records with a date between "1950-01-01" and "1950-12-31"
    Then the API should return record A
    
  Scenario: Date range search outside a date
    When I search the "sourceResource.temporal" field for records with a date between "1800-01-01" and "1850-12-31"
    Then the API should return no records

  Scenario: Date range search around a date range
    When I search the "sourceResource.temporal" field for records with a date between "1955-01-01" and "1955-12-31"
    Then the API should return record B
                                       
  Scenario: Date range search within a date range when record has multiple sourceResource.temporal records
    When I search the "sourceResource.temporal" field for records with a date between "1210" and "1220"
    Then the API should return record D

  Scenario: Date range search overlapping end of a date range
    When I search the "sourceResource.temporal" field for records with a date between "1975" and "1985"
    Then the API should return record C

  Scenario: Date range search overlapping beginning of a date range
    When I search the "sourceResource.temporal" field for records with a date between "1965" and "1975"
    Then the API should return record C

  Scenario: Date range search overlapping beginning of a date range
    When I search the "sourceResource.temporal" field for records with a date before "1100"
    Then the API should return no records

  Scenario: Date range search in the "sourceResource.date" field
    When I search the "sourceResource.date" field for records with a date between "1973-01-01" and "1973-12-31"
    Then the API should return record F

