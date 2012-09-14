Feature: Search for content by keyword (UC001)
	
	In order to find content through the DPLA
	API users should be able to search for content using free text search
	
	Scenario: Basic keyword search of title field
		Given that I have have a valid API key
	  	And there are metadata records that contain the word "banana" in the title
			And there are nt more than 10 records that contain the word "banana"
			And the default page size is 10
		When I search for "banana"
			And provide no other options
		Then the API should return all records with "banana" in the title		
		
	Scenario: Basic keyword search of description field
		Given that I have have a valid API key
		  And there are metadata records that contain the word "perplexed" in the description
			And there are no metadata records that contain the word "perplexed" in the title
			And there are not more than 10 records that contain the word "perplexed"
			And the default page size is 10
		When I search for "perplexed"
			And provide no other options
		Then the API should return all records with "perplexed" in the description

	Scenario: Basic keyword search of description field
		Given that I have have a valid API key
		  And there are metadata records that contain the word "perplexed" in the description
			And there are no metadata records that contain the word "perplexed" in the title
			And there are not more than 10 records that contain the word "perplexed"
			And the default page size is 10
		When I search for "perplexed"
			And provide no other options
		Then the API should return all records with "perplexed" in the description

