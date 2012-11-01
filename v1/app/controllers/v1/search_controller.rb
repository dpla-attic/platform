require_dependency "v1/application_controller"
require 'v1/item'

module V1
  class SearchController < ApplicationController

    def items
      results = V1::Item.search( params )
      render :json => results.to_json
    end

    def fetch
      ids = params[:ids].split(',')
      results = V1::Item.fetch( ids )
      render :json => results.to_json
    end

    def links
    end
  end
end
