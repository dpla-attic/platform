#require_dependency "contentqa/application_controller"

module Contentqa
  class SearchController < ApplicationController
    include Contentqa::SearchHelper

    DISPLAY = %w[id sourceResource.title sourceResource.description sourceResource.creator sourceResource.type sourceResource.publisher sourceResource.format sourceResource.rights sourceResource.contributor sourceResource.date sourceResource.spatial sourceResource.temporal sourceResource.subject sourceResource.ingestDate sourceResource.collection sourceResource.language.name]
    SEARCH = %w[id sourceResource.title sourceResource.description sourceResource.creator sourceResource.type sourceResource.publisher sourceResource.format sourceResource.rights sourceResource.contributor sourceResource.spatial sourceResource.date.after sourceResource.date.before sourceResource.subject.name sourceResource.collection]
    FACETS = %w[sourceResource.type sourceResource.format sourceResource.language.name sourceResource.spatial.name sourceResource.spatial.state sourceResource.spatial.city sourceResource.subject.name sourceResource.collection.title sourceResource.contributor]

    # add facets to PARAMETERS because anything facetable should also be searchable. Dupes are harmless here
    PARAMETERS = FACETS + %w[sourceResource.title sourceResource.description sourceResource.creator sourceResource.type sourceResource.publisher sourceResource.format sourceResource.rights sourceResource.contributor sourceResource.date.before sourceResource.date.after sourceResource.spatial.name sourceResource.spatial.state sourceResource.temporal.after sourceResource.temporal.before sourceResource.collection id q page_size facet_size page sourceResource.subject.name]

    def index
      api_params = params.delete_if { |key,value| PARAMETERS.exclude? key}
      api_params = api_params.delete_if { |key,value| value.to_s == '' }
      api_params = api_params.merge({'facets' => FACETS.join(",")})

      search_result = item_search(api_params)

      @count, @start, @limit = search_result['count'], search_result['start'], search_result['limit']
      @results = search_result['docs']
      @display_fields = DISPLAY
      @search_fields = SEARCH
      @page_size = params['page_size'].to_i == 0 ? 10 : params['page_size'].to_i
      @page_list = paginate(@count, @start, @limit, @page_size )
      @page_count = get_page_count(@count, @page_size)
      @facets = search_result['facets']
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
