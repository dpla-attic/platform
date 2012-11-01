Feature: Standard test dataset
  Background: 
    Given the dataset exists

  Scenario: Valid JSON dataset syntax
    When I have valid JSON in the test dataset
    Then I should not get a dataset error

  Scenario: Count Item records matching metadata fields
    And there are 1 items that contain the word "banana" in the "title"
    And there are 2 items that contain the word "perplexed" in the "description"
    And there are 0 items that contain the word "perplexed" in the "title"
   
  Scenario: Confirm Items with Metadata 
    And there is a metadata record "F" with "1973-04-19" in the "created" field 
    # And there is a metadata record "A" with "June 1, 1950" in the "temporal" field 
    # And there is a metadata record "B" with "July 1, 1955 - July 30, 1955" in the "temporal" field
    # And there is a metadata record "C" with "1970 - 1979 CE" in the "temporal" field
    # And there is a metadata record "D" with "1200 - 1250 CE" and "1270 - 1300 CE" in the "temporal" field
    # And there is a metadata record "E" with "2000-4000 BCE" in the "temporal" field   
