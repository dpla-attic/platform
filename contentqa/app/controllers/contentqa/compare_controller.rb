require_dependency "contentqa/application_controller"
require "httparty"

module Contentqa
  class CompareController < ApplicationController
    include HTTParty
    def index
 
      baseuri = request.protocol+request.host_with_port() 
      all_items_json = self.class.get(baseuri+v1_api.items_path()).body
      all_items = JSON.parse(all_items_json)
      target_item_json = self.class.get(baseuri+v1_api.items_path('page_size' => '1', 'page' => rand(all_items['count']))).body
      target_item = JSON.parse(target_item_json)
      
      doc = target_item['docs'][0]
      @original = JSON.pretty_generate(doc['dplaSourceRecord'])
      doc.delete_if { |key,_| ['dplaSourceRecord','@context','_rev','_id'].include? key}
      @twisted = JSON.pretty_generate(doc)

    end
  end
end
