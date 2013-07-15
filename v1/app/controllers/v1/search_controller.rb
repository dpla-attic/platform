require 'v1/application_controller'
require 'digest/md5'

#TODO: eliminate new duplication between resources here and break this into ItemsController and CollectionsController (to invert the current topology)
#TODO: Consider handling all our own exception classes in a: rescue_from SearchError

module V1

  class SearchController < ApplicationController
    before_filter :authenticate, :except => [:repo_status]  #, :links  #links is just here for testing auth
    rescue_from Errno::ECONNREFUSED, :with => :connection_refused
    rescue_from Exception, :with => :generic_exception_handler

    def base_cache_key(resource, action, unique_key='')
      # ResultsCache
      [
       'v2',
       resource,
       action,
       Digest::MD5.hexdigest( unique_key )
      ].join('-')
    end

    def search_cache_key(resource, params)
      # ResultsCache
      excluded = %w( api_key callback _ controller )
      key_hash = params.dup
      action = key_hash.delete('action')
      key_hash.delete_if {|k| excluded.include? k }

      base_cache_key(resource, action, key_hash.sort.to_s)
    end

    def fetch_cache_key(resource, params)
      # ResultsCache
      action = params['action']
      
      ids = params['ids'].to_s.split(/,\s*/)
      base_cache_key(resource, action, ids.sort.to_s)
    end
    
    def items
      begin
        results = Rails.cache.fetch(search_cache_key('items', params), :raw => true) do
          Item.search(params).to_json
        end
        render :json => render_as_json(results, params)
      rescue SearchError => e
        render_error(e, params)
      end
    end

    def fetch
      begin
        results = Rails.cache.fetch(fetch_cache_key('items', params), :raw => true) do
          Item.fetch(params[:ids].split(/,\s*/)).to_json
        end
        render :json => render_as_json(results, params)
      rescue NotFoundSearchError => e
        render_error(e, params)
      end
    end

    def collections
      begin
        results = Rails.cache.fetch(search_cache_key('collections', params), :raw => true) do
          Collection.search(params).to_json
        end
        render :json => render_as_json(results, params)
      rescue SearchError => e
        render_error(e, params)
      end
    end

    def fetch_collections
      begin
        results = Rails.cache.fetch(fetch_cache_key('collections', params), :raw => true) do
          Collection.fetch(params[:ids].split(/,\s*/)).to_json
        end
        render :json => render_as_json(results, params)
      rescue NotFoundSearchError => e
        render_error(e, params)
      end

    end

    def render_as_json(results, params)
      # Handles optional JSONP callback param
      conversion = results.is_a?(Hash) ? :to_json : :to_s

      if params['callback'].present?
        params['callback'] + '(' + results.send(conversion) + ')'
      else
        results.send(conversion)
      end
    end

    def repo_status
      status = :ok
      message = nil

      begin
        response = JSON.parse(Repository.service_status(true))
        
        if response['doc_count'].to_s == ''
          status = :error
          message = response.to_s
        end
      rescue Errno::ECONNREFUSED => e
        status = :service_unavailable
        message = e.to_s
      rescue => e
        status = :error
        message = e.to_s
      end

      logger.warn "REPO_STATUS Check: #{message}" if message
      head status
    end
    
    def connection_refused(exception)
      logger.warn "search_controller#connection_refused handler firing"
      render_error(ServiceUnavailableSearchError.new, params)
    end

    def generic_exception_handler(exception)
      logger.warn "#{self.class}.generic_exception_handler firing for: #{exception.class}: #{exception}"
      logger.warn "#{exception.backtrace.first(15).join("\n")}\n[SNIP]"
      render_error(InternalServerSearchError.new, params)
    end

    def render_error(e, params)
      render :json => render_as_json({:message => e.message}, params), :status => e.http_status
    end

    def links; end

  end

end
