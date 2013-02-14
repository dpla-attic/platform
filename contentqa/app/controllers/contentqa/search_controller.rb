require_dependency "contentqa/application_controller"

module Contentqa
  class SearchController < ApplicationController

    PARAMETERS = %w[aggregatedCHO.title aggregatedCHO.description aggregatedCHO.creator aggregatedCHO.publisher aggregatedCHO.physicalMedium aggregatedCHO.rights aggregatedCHO.type aggregatedCHO.contributor aggregatedCHO.date.before aggregatedCHO.date.after aggregatedCHO.spatial.name aggregatedCHO.spatial.state aggregatedCHO.temporal.after aggregatedCHO.temporal.before isPartOf id q page_size facet_size page aggregatedCHO.subject.name]
    DISPLAY = %w[id aggregatedCHO.title aggregatedCHO.description aggregatedCHO.creator aggregatedCHO.type aggregatedCHO.publisher aggregatedCHO.physicalMedium aggregatedCHO.rights aggregatedCHO.contributor aggregatedCHO.date aggregatedCHO.spatial aggregatedCHO.temporal aggregatedCHO.subject aggregatedCHO.ingestDate isPartOf]
    SEARCH = %w[id aggregatedCHO.title aggregatedCHO.description aggregatedCHO.creator aggregatedCHO.type aggregatedCHO.publisher aggregatedCHO.physicalMedium aggregatedCHO.rights aggregatedCHO.contributor aggregatedCHO.spatial aggregatedCHO.temporal.after aggregatedCHO.temporal.before aggregatedCHO.subject.name isPartOf]
    FACETS = %w[aggregatedCHO.type aggregatedCHO.physicalMedium aggregatedCHO.language.name aggregatedCHO.spatial.name aggregatedCHO.spatial.state aggregatedCHO.spatial.city aggregatedCHO.subject.name isPartOf.name aggregatedCHO.contributor]

    def index
      api_params = params.delete_if { |key,value| PARAMETERS.exclude? key}
      api_params = api_params.delete_if { |key,value| value.nil? || value.empty?}
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
