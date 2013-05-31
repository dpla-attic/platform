require 'test_helper'
require 'rails/performance_test_help'

class SearchTest < ActionDispatch::PerformanceTest
  # Refer to the documentation for all available options
  # self.profile_options = { :runs => 5 }
  #                          :output => 'tmp/performance', :formats => [:flat] }

  def setup
    @api_key = 'aa22c5ec71f95032dbcba4afc2041deb'
  end


  test "test_search_empty" do
    # get "/v2/items?api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?api_key=aa22c5ec71f95032dbcba4afc2041deb&page=12&page_size=50&q=Las%20Vegas&sourceResource.date.before=1980&sourceResource.type=%2Aimage%2A%20OR%20%2AImage%2A"
    # get "/v2/items?api_key=aa22c5ec71f95032dbcba4afc2041deb&page=14&page_size=50&q=Las%20Vegas&sourceResource.date.before=1980&sourceResource.type=%2Aimage%2A%20OR%20%2AImage%2A"
    # get "/v2/items?api_key=aa22c5ec71f95032dbcba4afc2041deb&page=1&page_size=50&q=boston%20AND%20street&sourceResource.date.before=1980&sourceResource.type=%2Aimage%2A%20OR%20%2AImage%2A"
    # get "/v2/items?api_key=aa22c5ec71f95032dbcba4afc2041deb&page=1&page_size=50&q=chicago%20AND%20gang&sourceResource.date.before=1980"
    # get "/v2/items?api_key=aa22c5ec71f95032dbcba4afc2041deb&page=1&page_size=50&q=chicago&sourceResource.date.before=1980"
    # get "/v2/items?api_key=aa22c5ec71f95032dbcba4afc2041deb&page=1&page_size=50&q=dancer&sourceResource.date.before=1980"
    # get "/v2/items?api_key=aa22c5ec71f95032dbcba4afc2041deb&page=2&page_size=50&q=Las%20Vegas&sourceResource.date.before=1980&sourceResource.type=%2Aimage%2A%20OR%20%2AImage%2A"
    # get "/v2/items?api_key=aa22c5ec71f95032dbcba4afc2041deb&page=3&page_size=50&q=boston%20AND%20street&sourceResource.date.before=1980&sourceResource.type=%2Aimage%2A%20OR%20%2AImage%2A"
    # get "/v2/items?api_key=aa22c5ec71f95032dbcba4afc2041deb&page=4&page_size=50&q=boston%20AND%20street&sourceResource.date.before=1980&sourceResource.type=%2Aimage%2A%20OR%20%2AImage%2A"
    # get "/v2/items?facets=sourceResource.date.begin.year&page_size=0&facet_size=2000&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?facets=sourceResource.date.begin.year&provider.name=%22South%20Carolina%20Digital%20Library%20-%20Clemson%22&sourceResource.spatial.name=%22Midlands%22&page_size=0&facet_size=2000&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?facets=sourceResource.date.begin.year&sourceResource.language.name=%22Catalan%22&sourceResource.subject.name=%22Catalonia%22&page_size=0&facet_size=2000&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?facets=sourceResource.date.begin.year&sourceResource.language.name=%22German%22&sourceResource.subject.name=%22Bern%22&page_size=0&facet_size=2000&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?facets=sourceResource.date.begin.year&sourceResource.language.name=%22Guarani%22&sourceResource.subject.name=%22Plants%22&page_size=0&facet_size=2000&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?facets=sourceResource.subject.name,sourceResource.language.name,sourceResource.type,dataProvider,provider.name,sourceResource.spatial.country,sourceResource.spatial.state,sourceResource.spatial.name&facet_size=100&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?facets=sourceResource.subject.name,sourceResource.language.name,sourceResource.type,dataProvider,provider.name,sourceResource.spatial.country,sourceResource.spatial.state,sourceResource.spatial.name&facet_size=100&provider.name=%22Digital%20Library%20of%20Georgia%22&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?facets=sourceResource.subject.name,sourceResource.language.name,sourceResource.type,dataProvider,provider.name,sourceResource.spatial.country,sourceResource.spatial.state,sourceResource.spatial.name&facet_size=100&provider.name=%22Mountain%20West%20Digital%20Library%22&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?facets=sourceResource.subject.name,sourceResource.language.name,sourceResource.type,dataProvider,provider.name,sourceResource.spatial.country,sourceResource.spatial.state,sourceResource.spatial.name&facet_size=100&provider.name=%22New%20York%20Public%20Library%22&sourceResource.spatial.name=%22United%20States%20--%20Maps%22&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?facets=sourceResource.subject.name,sourceResource.language.name,sourceResource.type,dataProvider,provider.name,sourceResource.spatial.country,sourceResource.spatial.state,sourceResource.spatial.name&facet_size=100&provider.name=%22South%20Carolina%20Digital%20Library%20-%20Clemson%22&sourceResource.spatial.name=%22Midlands%22&api_key=aa22c5ec71f95032dbcba4afc2041deb"

    # get "/v2/items?facets=sourceResource.subject.name,sourceResource.language.name,sourceResource.type,dataProvider,provider.name,sourceResource.spatial.country,sourceResource.spatial.state,sourceResource.spatial.name&facet_size=100&sourceResource.spatial.name=%22Paris%22&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?facets=sourceResource.subject.name,sourceResource.language.name,sourceResource.type,dataProvider,provider.name,sourceResource.spatial.country,sourceResource.spatial.state,sourceResource.spatial.name&facet_size=100&sourceResource.spatial.name=%22Thessaloniki%22&api_key=aa22c5ec71f95032dbcba4afc2041deb"

    get "/v2/items?facets=sourceResource.type%2CsourceResource.format%2CsourceResource.language.name%2CsourceResource.spatial.name%2CsourceResource.spatial.state%2CsourceResource.spatial.city%2CsourceResource.subject.name%2CsourceResource.collection.title%2CsourceResource.contributor&page=13&sourceResource.collection.title=%22General+Records+of+the+Department+of+Commerce%2C+1898+-+2000%22&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?facets=sourceResource.type%2CsourceResource.format%2CsourceResource.language.name%2CsourceResource.spatial.name%2CsourceResource.spatial.state%2CsourceResource.spatial.city%2CsourceResource.subject.name%2CsourceResource.collection.title%2CsourceResource.contributor&page=13&sourceResource.collection.title=%22LYRASIS+Members+and+Sloan+Foundation%22&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?fields=id,sourceResource.title,isShownAt,object,sourceResource.type,sourceResource.creator,sourceResource.spatial.name,sourceResource.spatial.coordinates&api_key=aa22c5ec71f95032dbcba4afc2041deb&callback=jQuery18308024057883303612_1365965461391&sourceResource.date.begin=2010"
    # get "/v2/items?fields=id,sourceResource.title,isShownAt,object,sourceResource.type,sourceResource.creator,sourceResource.spatial.name,sourceResource.spatial.coordinates&api_key=aa22c5ec71f95032dbcba4afc2041deb&callback=jQuery18308842038125731051_1365966840411&sourceResource.spatial.state=Montana&page_size=50"
    # get "/v2/items?fields=id,sourceResource.title,isShownAt,object,sourceResource.type,sourceResource.creator,sourceResource.spatial.name,sourceResource.spatial.coordinates&api_key=aa22c5ec71f95032dbcba4afc2041deb&callback=jQuery18309695308385416865_1365938298281&sourceResource.date.before=1976&sourceResource.date.after=1976"
    # get "/v2/items?id=21fc89c23e5d0171118eb43061c7ac2c&fields=id,sourceResource.title,isShownAt,object,sourceResource.type,sourceResource.creator,sourceResource.spatial.name,sourceResource.spatial.coordinates&&api_key=aa22c5ec71f95032dbcba4afc2041deb&callback=jQuery18304508480643853545_1365966059333"
    # get "/v2/items?id=21fc89c23e5d0171118eb43061c7ac2c&fields=id,sourceResource.title,isShownAt,object,sourceResource.type,sourceResource.creator,sourceResource.spatial.name,sourceResource.spatial.coordinates&&api_key=aa22c5ec71f95032dbcba4afc2041deb&callback=jQuery18306170200572814792_1365966099024"
    # get "/v2/items?id=21fc89c23e5d0171118eb43061c7ac2c&fields=id,sourceResource.title,isShownAt,object,sourceResource.type,sourceResource.creator,sourceResource.spatial.name,sourceResource.spatial.coordinates&&api_key=00529aa4925f81abc77f75"
    # get "/v2/items?isPartOf.name&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?page_size=0&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?page_size=300&page=1&aggregatedCHO.title=Annual%20report&aggregatedCHO.publisher=Government%20Printing%20Office&aggregatedCHO.date.after=1910&sort_by=aggregatedCHO.date.begin&"
    # get "/v2/items?provider.name=Biodiversity%20Heritage%20Library&sourceResource.type=%22text%22&page_size=50&sort_by=sourceResource.date.begin&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?q=banana&fields=id,sourceResource.title,isShownAt,object,sourceResource.type,sourceResource.creator,sourceResource.spatial.name,sourceResource.spatial.coordinates&api_key=aa22c5ec71f95032dbcba4afc2041deb&callback=jQuery18308727918355725706_1365956279485&sourceResource.date.before=1982&sourceResource.date.after=1982"
    # get "/v2/items?q=banan&facets=sourceResource.subject.name,sourceResource.language.name,sourceResource.type,dataProvider,provider.name,sourceResource.spatial.country,sourceResource.spatial.state,sourceResource.spatial.name&facet_size=100&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?q=cat&facets=sourceResource.date.begin.year&page_size=0&facet_size=2000&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?q=civil%20war&facets=sourceResource.subject.name,sourceResource.language.name,sourceResource.type,dataProvider,provider.name,sourceResource.spatial.country,sourceResource.spatial.state,sourceResource.spatial.name&facet_size=100&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?q=civil&sourceResource.date.after=1971-01-01&sourceResource.date.before=1971-12-31&page_size=0&api_key=aa22c5ec71f95032dbcba4afc2041deb&callback=jQuery18309267228781245649_1365955452031"
    # get "/v2/items?q=declaration%20of%20independence&facets=sourceResource.subject.name,sourceResource.language.name,sourceResource.type,dataProvider,provider.name,sourceResource.spatial.country,sourceResource.spatial.state,sourceResource.spatial.name&facet_size=100&sourceResource.spatial.name=%22United%20States%20--%20Maps%22&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?q=dinosaurs&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?q=Embalming%20Fluid&facets=sourceResource.subject.name,sourceResource.language.name,sourceResource.type,dataProvider,provider.name,sourceResource.spatial.country,sourceResource.spatial.state,sourceResource.spatial.name&facet_size=100&api_key=aa22c5ec71f95032dbcba4afc2041deb"
    # get "/v2/items?q=yolk&facets=sourceResource.subject.name,sourceResource.language.name,sourceResource.type,dataProvider,provider.name,sourceResource.spatial.country,sourceResource.spatial.state,sourceResource.spatial.name&facet_size=100&api_key=aa22c5ec71f95032dbcba4afc2041deb"

  end
end
