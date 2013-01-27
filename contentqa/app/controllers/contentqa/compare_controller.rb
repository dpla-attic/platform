require_dependency "contentqa/application_controller"

module Contentqa
  class CompareController < ApplicationController

    def index
      baseuri = request.protocol+request.host_with_port()
      fetch = HTTParty.get(baseuri+v1_api.items_path('page_size' => '1'))
      @total = fetch.parsed_response['count'] 
      @id = params[:id]

      if @id
        fetch = HTTParty.get(baseuri+v1_api.items_path()+'/'+@id)

        if fetch.success?
          doc = fetch.parsed_response['docs'].first
        else
          raise Exception, "ElasticSearch fetch returned 404 for: #{@id}"
        end
      else
        doc = get_random_doc(baseuri, fetch.parsed_response['count'])
     end
      
      @original = JSON.pretty_generate(doc['dplaSourceRecord'])
      doc.delete_if { |key,_| ['dplaSourceRecord','@context','_rev','_id'].include? key}
      @twisted = JSON.pretty_generate(doc)
      @link = baseuri+v1_api.items_path()+'/'+doc['id']
      @next = get_random_doc(baseuri, fetch.parsed_response['count'])['id']
    end

    def get_random_doc(baseuri, count)
      @page = rand(count)
      fetch = HTTParty.get(baseuri+v1_api.items_path('page_size' => '1', 'page' => @page))

      doc = fetch.parsed_response['docs'].first
    end

  end
end
