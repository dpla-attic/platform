require_dependency "contentqa/application_controller"

module Contentqa
  class CompareController < ApplicationController

    def index
      fetch = item_search({'page_size' => '0'})  #HTTParty.get(baseuri+v1_api.items_path('page_size' => '0'))
      @total = fetch['count']
      @id = params[:id]

      if @id
        begin
          fetch = item_fetch(@id)  #HTTParty.get(baseuri+v1_api.items_path()+'/'+@id)
          doc = fetch['docs'].first
        rescue V1::NotFoundSearchError
          raise Exception, "ElasticSearch fetch returned 404 for: #{@id}"
        end
      else
        doc = get_random_doc(baseuri, fetch['count'])
     end
      
      @original = JSON.pretty_generate(doc['originalRecord'] || {})
      doc.delete_if { |key,_| %w[ score originalRecord @context _rev _id ].include? key}
      @twisted = JSON.pretty_generate(doc)
      @link = item_fetch_link(doc['id'])
      @next = get_random_doc(baseuri, fetch['count'])['id']
    end

    def get_random_doc(baseuri, count)
      @page = rand(count)
      fetch = item_search({'page_size' => '1', 'page' => @page})

      fetch['docs'].first
    end

  end
end
