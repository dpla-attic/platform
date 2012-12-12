require_dependency "contentqa/application_controller"
require "httparty"

module Contentqa
  class SearchController < ApplicationController
    include HTTParty
    PARAMETERS = %w[title description creator type publisher format rights contributor created spatial temporal.after temporal.before source id q page_size page ]
    DISPLAY = %w[id title description creator type publisher format rights contributor created spatial temporal source ingestDate]
    SEARCH = %w[id title description creator type publisher rights contributor spatial temporal.after temporal.before]
    def index
      baseuri = request.protocol+request.host_with_port() 
      api_params = params.delete_if { |key,value| !PARAMETERS.include? key}
      api_params = api_params.delete_if { |key,value| value.nil? || value.empty?}

      json = self.class.get(baseuri+v1_api.items_path(api_params)).body
      search_result = JSON.parse(json)

      @count, @start,  @limit = search_result['count'], search_result['start'], search_result['limit']
      @results = search_result['docs']
      @display_fields = DISPLAY
      @search_fields = SEARCH
      @page_size = params['page_size'].nil? || params['page_size'] == 0 ? 10 : params['page_size'].to_i
      @page_list = paginate(@count, @start, @limit, @page_size )
      @page_count = get_page_count(@count, @page_size)
    end

    def get_page_count (count, page_size)
      count / page_size + (count % page_size > 0 ? 1 : 0) 
    end

    def paginate (count, start, limit, page_size)
      page_count = get_page_count count, page_size
      current_page = start / page_size + (start % page_size > 0 ? 1 : 0) 
      if count == 0 
        return (), 0
      end
      if (current_page < 10)
        (1..[page_count,20].min)
      else
        ([1,current_page - 10].max..[page_count,current_page + 10].min)
      end

    end
      

  end
end
