Feature: Search for collections by keyword (UC027)
  
  In order to find content through the DPLA
  API users should be able to search for collections using free text search

  Given that I have have a valid API key
    And the default test dataset is loaded

  Scenario: Free text collection search with hits on the title
    When I collection-search for "apple"
    Then the API should return 1 collections with "apple"

  @wip
  Scenario: Faceted search of collections
    When I collection-search for "apple"
      And request the "language" facet
    Then the API should return the collection with identifier "coll1"
      And the API should return the "language" facet
      And the "language" facet should contain items for every unique language within the full result set
      And the each item within the facet should contain a count of matching items
    
    
