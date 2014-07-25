module Contentqa

  class ReportingController < ApplicationController
    include ReportingHelper
    rescue_from RestClient::ResourceNotFound, :with => :generic_exception_handler
    rescue_from Exception, :with => :generic_exception_handler

    def generic_exception_handler(exception)
      logger.warn "#{self.class}.generic_exception_handler firing for: #{exception.class}: #{exception}"
      logger.warn "#{exception.backtrace.first(15).join("\n")}\n[SNIP]"
      render :text => "Unexpected error querying report views: #{exception.message}", :status => :error
    end

    def index
      @providers = Reports.find_last_ingests
    end

    def provider
      @ingest = find_ingest
      @reports = Reports.find_report_types("provider").inject({}) do |memo, type|
        memo[type] = {
          :file => Reports.get_report(@ingest['_id'], type),
          :job => Delayed::Job.find_by_queue("#{params[:id]}_#{type}")
        }
        memo
      end
      if Reports.all_created?(params[:id])
        @all_reports = Reports.get_zipped_reports(@ingest['_id'], @ingest['provider'])
      end

      respond_to do |format|
        format.js
        format.html
      end
    end

    def global
      @global_reports_id = Reports.get_global_reports_id
      @reports = Reports.find_report_types("global").inject({}) do |memo, type|
        memo[type] = {
          :file => Reports.get_report(@global_reports_id, type),
          :job => Delayed::Job.find_by_queue("#{@global_reports_id}_#{type}")
        }
        memo
      end

      if Reports.all_created?(params[:id])
        @all_reports = Reports.get_zipped_reports(@global_reports_id, "global")
      end

      respond_to do |format|
        format.js
        format.html
      end
    end

    def errors
      @ingest = find_ingest
    end

    def create
      if params[:reports]
        params[:reports].each do |report_type|
          Reports.delay(:queue => "#{params[:id]}_#{report_type}").create_report(params[:id], report_type)
        end
      end

      action = params[:provider] == "global" ? :global : :provider
      redirect_to action: action, id: params[:id]
    end

    def download
      if params[:report_type] == "all"
        path = Reports.all_reports_path params[:id]
        type = "application/zip"
        if params[:id] =~ /global/
          filename = "global.zip"
        else
          @ingest = find_ingest
          filename = "#{@ingest['provider']}.zip"
        end
      else
        path = Reports.report_path params[:id], params[:report_type]
        type = "text/csv"
        filename = params[:report_type]
      end

      if path
        send_file path, :type => type, :filename => filename
      else
        render status: :forbidden, text: "Access denied"
      end
    end

    def find_ingest
      Reports.find_ingest params[:id]
    end

  end
end
