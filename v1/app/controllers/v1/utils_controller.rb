require 'v1/bulk_download'

module V1

  class UtilsController < ApplicationController
    before_filter :authenticate
    #rescue_from Exception, :with => :generic_exception_handler
    rescue_from Errno::ECONNREFUSED, :with => :connection_refused

    def contributor_bulk_download_links
      render :json => BulkDownload.contributor_links
    end

  end

end
