Feature: Boost certain fields at query time
  
  In order to boost search hits on certain fields
  The API should boost relevancy in boosted fields and sort by that relevancy
                                                       
  Background:
    Given that I have a valid API key
      And the default test dataset is loaded
      And the default test field boosts are defined
      
  Scenario: Sanity check our target test docs
    When I item-search for "reddit"
    Then the API should return record b1, b2, b3
      
  Scenario: Keyword search with hits only on unboosted fields with different base relevancy
    When I item-search for "nalgene"
    Then the API should return results sorted by relevancy

  Scenario: Keyword search with hits only on unboosted fields with different base relevancy (reverse)
    When I item-search for "spoon"
    Then the API should return results sorted by relevancy

  Scenario: Keyword search with hits in three differently boosted fields
    When I item-search for "reddit"
    Then the API should return sorted records b2, b1, b3

  Scenario: Keyword search with hits in boosted and unboosted fields
    When I item-search for "pomegranate"
    Then the API should return sorted records b3, b2

  Scenario: Keyword search with hit on subfield of a boosted parent field
    When I item-search for "ferrari"
    Then the API should return sorted records b2, b1

  Scenario: Field search of parent field with hit on both unboosted and boosted subfields
    When I item-search for "isengard" in the "sourceResource.spatial" field
    Then the API should return sorted records b3, b2

  Scenario: Keyword search for collections with hits in boosted and unboosted fields
    When I collection-search for "altoid"
    Then the API should return sorted records coll5, coll4

