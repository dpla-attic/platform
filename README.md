The DPLA Platform
--------

The Search API provides read-only access to metadata records in the DPLA repository.

# The Basics

* You can run queries to search for items from the metadata repository
* All results are returned as [JSON-LD](http://json-ld.org/).

# API access

All API search and fetch requests must include an API access key parameter named 'api_key' containing a valid API key. Example:

http://api.dp.la/v2/items?api_key=YOUR_API_KEY

## Requesting an API access key

To request an API access key, simply make a HTTP **POST** request that includes your email address. Your API access key will be emailed to you. Example:

curl -v -XPOST  http://api.dp.la/v2/api_key/you@your_email.com

# Sample Queries

## A basic search 

### All items that contain "fruit" in any field:

<http://api.dp.la/v2/items?q=fruit>

## Boolean and wildcard search

### boolean "AND" 

<http://api.dp.la/v2/items?q=fruit+AND+banana>

### "*" wildcard

<http://api.dp.la/v2/items?q=*anana>

## Search a specific field with "AND" boolean

<http://api.dp.la/v2/items?sourceResource.description=perplexed+AND+Hennepin>

## Search a specific field or fields

### All items that contain "fruit" in the title:

<http://api.dp.la/v2/items?sourceResource.title=fruit>

### All items that contain "fruit" in the title and "basket" in the description:

<http://api.dp.la/v2/items?sourceResource.title=fruit&sourceResource.description=basket>

### Fields available for text search are (UPDATE):

* sourceResource.title
* sourceResource.description
* sourceResource.subject
* sourceResource.creator
* sourceResource.type
* sourceResource.publisher
* sourceResource.format
* sourceResource.rights
* sourceResource.contributor
* sourceResource.spatial
* isPartOf
* provider

## Search by date

* date - A date or date range corresponding to creation date of the item metadata record is about. For example, a journal entry from May 1, 1863, or a photograph taken sometime between 1920 and 1925.

### Items from before 1900:

<http://api.dp.la/v2/items?sourceResource.date.before=1900>
 
### Items from after 1980:

<http://api.dp.la/v2/items?sourceResource.date.after=1980>
 
### Items from November of 1963 (aka "between" two dates)

<http://api.dp.la/v2/items?sourceResource.date.after=1963-11-01&sourceResource.date.before=1963-11-30>

## Search by location

The location of the item the metadata record is about is maintained in the 'sourceResource.spatial' field

### Items where the string "Cambridge" is part of the location

<http://api.dp.la/v2/items?sourceResource.spatial=Cambridge>
                                                                           
### Items in the city of Cambridge (more specific sourceResource.spatial search)

<http://api.dp.la/v2/items?sourceResource.spatial.city=Cambridge>

### Items in the state of Massachusetts

_Note: sourceResource.spatial.state and sourceResource.spatial.iso3166-2 data is not yet available_

<http://api.dp.la/v2/items?sourceResource.spatial.state=Massachusetts> (using the full name)

<http://api.dp.la/v2/items?sourceResource.spatial.iso3166-2=US-MA> (using ISO3166-2)

### Items near a coordinate location

<http://api.dp.la/v2/items?sourceResource.spatial.coordinates=42.3,-71> (within 20 miles, the default)

<http://api.dp.la/v2/items?sourceResource.spatial.coordinates=42.3,-71&sourceResource.spatial.distance=100mi> (within 100 miles, 'mi' or 'km' units required)

### Items inside a coordinate bounding box

Add a second coordinate to the above coordinate search to search for items inside a bounding box. The first coordinate defines the upper left corner of the bounding box, and the second coordinate defines the lower right corner. Separate the two coordinates with a colon. 

http://api.dp.la/v2/items?sourceResource.spatial.coordinates=42.93,-72.28:41.76,-70.48

## Paginate results

The default page size is 10 records. The maximum page size is 100 records. You can set page_size=0 to just get facets, or the "total" field, etc.

### Retrieve more records in a single request
<http://api.dp.la/v2/items?q=town&page_size=25>

### Retrieve more records in a single request, but page 2
Retrieve next page of results with custom page size
<http://api.dp.la/v2/items?q=town&page_size=25&page=2>

## Sort results 

The default sort order is ascending. Most, but not all fields can be sorted on. Attempts to sort on an un-sortable field will return the standard error structure with a HTTP 400 status code.

### Sort by title
<http://api.dp.la/v2/items?q=fruit&sort_by=sourceResource.title>

### Sort by subject.name
<http://api.dp.la/v2/items?q=fruit&sort_by=sourceResource.subject.name>

### Sort by date.begin date
<http://api.dp.la/v2/items?q=fruit&sort_by=sourceResource.date.begin>

### Sort by date.begin date ascending (which again, is the default)
<http://api.dp.la/v2/items?q=fruit&sort_by=sourceResource.date.begin&sort_order=asc>

### Sort by date.begin date descending
<http://api.dp.la/v2/items?q=fruit&sort_by=sourceResource.date.begin&sort_order=desc>

### Sort by geo_distance from a given coordinate
<http://api.dp.la/v2/items?sort_by=sourceResource.spatial.coordinates&sort_by_pin=41.3,-71>

Sorting by geo_distance requires a coordinate value in an additional sort_by_pin parameter. The sort_by_pin parameter defines the point from which all search results will have their distances computed and sorted. Its format is the same format used when querying for a specific value in the sourceResource.spatial.coordinates field. The sort_order parameter behaves the same way for geo_distance sorts as it does when sorting on any other type of field.

## Fetch individual fields

### Request only the title and id fields 

<http://api.dp.la/v2/items?q=town&fields=sourceResource.title,id>

## Fetch individual items

### Retrieve an item by its 'id' value

<http://api.dp.la/v2/items/a4e2346032cae75b0832abe064c14bcb>

### Retrieve multiple items by their 'id' values

<http://api.dp.la/v2/items/a4e2346032cae75b0832abe0644e9b26,a4e2346032cae75b0832abe064c14bcb> (comma separated IDs)

## Facets

Facets can be requested on their own or as part of a search query. Facets requested on their own will be global facets. Facets requested as part of a search query will be constrained to the results of that search query. A facet's "type" is dictated by a given field's type within the DPLA schema. (Basic facets are almost always "string" type fields that are not tokenized.) All non-geo-distance facets are sorted by their "count" field, descending. Not all fields in the schema are facetable. 

### Basic facets

<http://api.dp.la/v2/items?facets=sourceResource.spatial.name> (facets for a single field)

<http://api.dp.la/v2/items?facets=sourceResource.spatial.name,sourceResource.language.name> (facets for a multiple fields, specified as comma separated list of field names)

### Retrieve facets **only** (no documents in results set)

<http://api.dp.la/v2/items?facets=sourceResource.date.begin&page_size=0

### Auto-expanded facets

A request for facets on a field that contains sub-fields are **always** be expanded to include all that field's facet-able sub-fields. If a field has no facet-able sub-fields, that request will return an error. If a field has a mix of facet-able and non-facet-able sub-fields, only the facet-able sub-fields will be used, and no error will be returned. For maximum performance, only request the facets you want. I.e. Don't request facets on the sourceResource.spatial field when you only want the facets on the sourceResource.subject.city field. Examples: 

<http://api.dp.la/v2/items?facets=sourceResource.subject> (request facets for a single field with a mix of facet-able and non-facet-able sub-fields)

That will be auto-expanded into this equivalent query: 

<http://api.dp.la/v2/items?facets=sourceResource.subject.@id,sourceResource.subject.name>

### Date facets

Date facets are returned in YYYY-MM-DD format by default.

<http://api.dp.la/v2/items?facets=sourceResource.date.begin>

### Date facets with buckets

Facets on a date field can be grouped by the following logical buckets: century, decade, year, month, day. Returned facets are formatted to the appropriate level of accuracy. The default format is "day". 

<http://api.dp.la/v2/items?facets=sourceResource.date.begin.year>

### Geo-distance facets with ranges

Facets on a geo_point field (e.g. sourceResource.spatial.coordinates) require additional data in the query parameter. The additional information is used to define the point from which all distances are computed. We call that the "pin." There is also an option range parameter (to define the size of the facet) with an optional units parameter. The API will take your range parameter (or the default) and generate 10 facet buckets for it.

<http://api.dp.la/v2/items?facets=sourceResource.spatial.coordinates:42.3:-71:20mi>

* sourceResource.spatial.coordinates - the geo_point field you want to facet on
* 42.3 - the pin latitude
* -71 - the pin longitude
* 20 - the facet range size. Optional. Default is 50.
* mi - the facet range units. Optional. Default is "mi". Valid values are "mi" or "km". You can also specify the range units while omitting the range size in order to use the default range size but with your choice of range units. (See below.)

Example URLS showing valid uses of default values:
* <http://api.dp.la/v2/items?facets=sourceResource.spatial.coordinates:42.3:-71> (default range size, default range units)
* <http://api.dp.la/v2/items?facets=sourceResource.spatial.coordinates:42.3:-71:20> (specific range size, default range units)
* <http://api.dp.la/v2/items?facets=sourceResource.spatial.coordinates:42.3:-71:km> (default range size, specific range units)
* <http://api.dp.la/v2/items?facets=sourceResource.spatial.coordinates:42.3:-71:20km> (specific range size, specific range units)

Note that this format still allows requesting multiple facets in a comma-separated list. E.g: 

<http://api.dp.la/v2/items?facets=sourceResource.spatial.coordinates:42.3:-71:20mi,sourceResource.spatial.state>

### Facet limits

There is a default limit of 50 facets returned per query. You can request more or less facets via the facet_size param, up to the limit of 2000. E.g: 

<http://api.dp.la/v2/items?facets=sourceResource.date.begin.year&facet_size=3>

### Facet sorting

Terms and date facets are sorted by facet-count, descending. Geo-distance facets (on sourceResource.spatial.coordinates) are sorted by the distance from your sort_by_pin param's coordinates, ascending. We have plans to give the user control over this sort order.

# Response Format

## The Basics

### The response is in [JSON-LD](http://json-ld.org/) format. The following fields may be populated:

* @id
* id
* sourceResource.contributor
* sourceResource.creator
* sourceResource.date.displayDate
* sourceResource.date.begin
* sourceResource.date.end
* sourceResource.description
* sourceResource.extent
* sourceResource.language.name
* sourceResource.language.iso639
* sourceResource.physicalMedium
* sourceResource.publisher
* sourceResource.rights
* sourceResource.relation
* sourceResource.stateLocatedIn.name
* sourceResource.stateLocatedIn.iso3166-2
* sourceResource.spatial.name
* sourceResource.spatial.country
* sourceResource.spatial.region
* sourceResource.spatial.county
* sourceResource.spatial.state
* sourceResource.spatial.city
* sourceResource.spatial.iso3166-2
* sourceResource.spatial.coordinates
* sourceResource.spatial.distance
* sourceResource.subject.@id
* sourceResource.subject.@type
* sourceResource.subject.name
* sourceResource.temporal.begin
* sourceResource.temporal.end
* sourceResource.title
* sourceResource.type
* dataProvider
* hasView.@id
* hasView.format
* hasView.rights
* isPartOf.@id
* isPartOf.name
* isShownAt.@id
* isShownAt.format
* isShownAt.rights
* object.@id
* object.format
* object.rights
* provider.@id
* provider.name

            
### JSONP

Add a 'callback' parameter to receive the results wrapped in a function

<http://api.dp.la/v2/items?sourceResource.title=fruit&callback=myFunc>


### Sample Record

    {
       "id": "ecbcaeaaf85e7f7cced0723f13499f6a"
       "@id": "http://dp.la/api/items/ecbcaeaaf85e7f7cced0723f13499f6a",
       "@context": {
           "begin": {
               "@id": "dpla:dateRangeStart",
               "@type": "xsd:date"
           },
           "@vocab": "http://purl.org/dc/terms/",
           "hasView": "edm:hasView",
           "name": "xsd:string",
           "object": "edm:object",
           "sourceResource": "edm:sourceResource",
           "dpla": "http://dp.la/terms/",
           "collection": "dpla:aggregation",
           "edm": "http://www.europeana.eu/schemas/edm/",
           "state": "dpla:state",
           "aggregatedDigitalResource": "dpla:aggregatedDigitalResource",
           "coordinates": "dpla:coordinates",
           "isShownAt": "edm:isShownAt",
           "provider": "edm:provider",
           "stateLocatedIn": "dpla:stateLocatedIn",
           "end": {
               "@id": "dpla:dateRangeEnd",
               "@type": "xsd:date"
           },
           "dataProvider": "edm:dataProvider",
           "originalRecord": "dpla:originalRecord",
           "LCSH": "http://id.loc.gov/authorities/subjects"
       },
       "dataProvider": "Published by Office of Athletic Publicity, Clemson University Item is located in Clemson University Libraries Special Collections, Strom Thurmond Institute Building",
       "admin": {
           "object_status": "pending"
       },
       "originalRecord": {
           "publisher": [
               "Special Collections, Clemson University Libraries",
               "Clemson University Libraries"
           ],
           "handle": [
               "cfb029",
               "http://repository.clemson.edu/u?/cfb,1001"
           ],
           "description": "Official souvenir program of the Clemson -Presbyterian game held September 20, 1952 at Memorial Stadium; 35 cents",
           "language": "English",
           "format": [
               "image/jpeg",
               "Images"
           ],
           "type": "Still Image",
           "rights": "Contact Special Collections for copyright information",
           "contributor": "Lon Keller (illustrator)",
           "label": "Football program. Clemson - Presbyterian, September 20, 1952, Memorial Stadium",
           "source": "Published by Office of Athletic Publicity, Clemson University Item is located in Clemson University Libraries Special Collections, Strom Thurmond Institute Building",
           "relation": "Publications of the Department of Athletics, Series 44, Special Collections, Clemson University Libraries, Clemson, S.C.",
           "coverage": [
               "Pickens County (S.C.) ; Laurens County (S.C.)",
               "Upstate"
           ],
           "date": [
               "1952-09-20",
               "2008-11-18"
           ],
           "datestamp": "2009-10-30",
           "title": "Football program. Clemson - Presbyterian, September 20, 1952, Memorial Stadium",
           "creator": "Clemson University. Athletic Dept. From Athletic Department records, Series 40, Special Collections, Clemson University Libraries",
           "id": "oai:repository.clemson.edu:cfb/1001",
           "subject": "Clemson Agricultural College of South Carolina--Football--History; Presbyterian College; Football--South Carolina--Clemson; Souvenir programs"
       },
       "object": {
           "format": "",
           "@id": "http://repository.clemson.edu/cgi-bin/thumbnail.exe?CISOROOT=/cfb&CISOPTR=1001",
           "rights": "Contact Special Collections for copyright information"
       },
       "sourceResource": {
           "publisher": [
               "Special Collections, Clemson University Libraries",
               "Clemson University Libraries"
           ],
           "rights": "Contact Special Collections for copyright information",
           "description": "Official souvenir program of the Clemson -Presbyterian game held September 20, 1952 at Memorial Stadium; 35 cents",
           "language": {
               "name": "English"
           },
           "title": "Football program. Clemson - Presbyterian, September 20, 1952, Memorial Stadium",
           "creator": "Clemson University. Athletic Dept. From Athletic Department records, Series 40, Special Collections, Clemson University Libraries",
           "physicalmedium": "Images",
           "date": {
               "begin": "1952-09-20",
               "end": "1952-09-20",
               "displayDate": "1952-09-20"
           },
           "relation": "Publications of the Department of Athletics, Series 44, Special Collections, Clemson University Libraries, Clemson, S.C.",
           "spatial": [
               {
                   "name": "Pickens County (S.C.) ; Laurens County (S.C.)"
               },
               {
                   "name": "Upstate"
               }
           ],
           "contributor": "Lon Keller (illustrator)",
           "type": "image",
           "subject": [
               {
                   "name": "Clemson Agricultural College of South Carolina--Football--History"
               },
               {
                   "name": "Presbyterian College"
               },
               {
                   "name": "Football--South Carolina--Clemson"
               },
               {
                   "name": "Souvenir programs"
               }
           ]
       },
       "ingestDate": "2013-02-06T20:07:32.165986",
       "collection": {
           "@id": "http://dp.la/api/collections/clemson--cfb",
           "name": "Clemson University Football Program Covers"
       },
       "provider": {
           "@id": "http://dp.la/api/contributor/scdl-clemson",
           "name": "South Carolina Digital Library - Clemson"
       },
       "isShownAt": {
           "format": "image/jpeg",
           "@id": "http://repository.clemson.edu/u?/cfb,1001",
           "rights": "Contact Special Collections for copyright information"
       },
       "ingestType": "item"
    }

### A list of records


    {
      "count" : "23423",
      "start" : "0",
      "limit" : "10",
      "docs" : [
        { .... },
        { .... },
        ....
        { .... }
       ],
      "facets" : [
        { .... },
        { .... },
        ....
        { .... }
       ]
    }

Build Status
--------
[![Build Status](https://secure.travis-ci.org/dpla/platform.png?branch=develop)](http://travis-ci.org/dpla/platform)


License
--------
This application is released under a AGPLv3 license.

Copyright President and Fellows of Harvard College, 2012

