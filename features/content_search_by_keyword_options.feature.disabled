Feature: Search for content by keyword with options (UC001)
	
	In order to find content through the DPLA        
	And customize the data returned through the API
	And navigate through the data
	API users should be able to search for content using free text search
	And request a specific set of fields to be returned
	And view different pages of results
	And retrive facets for faceted search
	
	Scenario: Basic keyword search returning specific fields
		Given that I have have a valid API key
		  And there are metadata records that contain the word "banana"
		When I search for "banana"
			And request the fields "title" and "description"
		Then the API should return all records with "banana" in the title
			And return the records in JSON format
			And only include the "id", "title", and "description" fields in the records returned
