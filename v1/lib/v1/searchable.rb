require_relative 'search_error'
require_relative 'repository'
require_relative 'schema'
require_relative 'json_ld'
require_relative 'searchable/facet'
require_relative 'searchable/filter'
require_relative 'searchable/query'
require_relative 'searchable/sort'
require 'httparty'
require 'active_support/core_ext'

module V1

  module Searchable

    # Default pagination size for search results
    DEFAULT_PAGE_SIZE = 10

    # Default max page size
    MAX_PAGE_SIZE = 500

    # Maximum page number
    MAX_PAGE_NUM = 100
    
    # General query params that are not resource-specific
    BASE_QUERY_PARAMS = %w( q controller action sort_by sort_by_pin sort_order
                            page page_size facets facet_size filter_facets
                            fields callback _ x exact_field_match ).freeze

    def resource
      raise "Modules extending Searchable must define resource() method"
    end

    def build_queries(resource, filtered_search, params)
      queries = []
      queries << Searchable::Query.build_all(resource, filtered_search, params)
      queries << Searchable::Filter.build_all(resource, filtered_search, params)
      queries.any?
    end

    def build_sort(resource, params)
      Searchable::Sort.build_sort_attributes(resource, params)
    end

    def search(params={})
      validate_query_params(params)
      validate_field_params(params)

      query_part = {
        'query' => Searchable::Query.build_all(resource, params)
      }
      facet_part =
        !params['facets'].blank? \
        ? {'aggs' => Searchable::Facet.build_all(resource, params)} \
        : {}
      sort_part = {'sort' => build_sort(resource, params)}
      offset_part = {'from' => search_offset(params)}
      pagesize_part = {'size' => search_page_size(params)}
      req_body =
        query_part.merge(facet_part).merge(sort_part).merge(offset_part)
          .merge(pagesize_part).merge(search_fields(params))

      begin
        url = Config.search_endpoint + '/' + Config.search_index + '/' +
          resource + '/_search?search_type=dfs_query_then_fetch'
        if (!Rails.env.testing? rescue false)
          Rails.logger.debug "ES URL: #{url}"
          Rails.logger.debug "ES QUERY: #{req_body.to_json}"
        end
        http_response = HTTParty.post(
          url,
          {
            :body => req_body.to_json,
            :headers => {
              'Content-Type' => 'application/json',
              'Accept' => 'application/json'
            }
          }
        )
        code = http_response.response.code
        case code
        when "200"
          result = http_response.to_hash
          return wrap_results(result, params)
        else
          if (!Rails.env.testing? rescue false)
            Rails.logger.error "Got HTTP #{code} from Elasticsearch for\n#{req_body.to_json}"
            Rails.logger.error "\n#{http_response.body}"
          end
          raise InternalServerSearchError, "Got error response from search engine"
        end
      rescue InternalServerSearchError
        raise
      rescue => e
        if (!Rails.env.testing?)
          Rails.logger.error e.message
          Rails.logger.error e.backtrace.join("\n")
        end
        raise InternalServerSearchError, "Encountered an unexpected error querying search engine"
      end
    end

    def search_fields(params)
      if params['fields'].present?
        {'_source' => params['fields'].to_s.split(/,\s*/)}
      else
        {}
      end
    end

    def search_offset(params)
      page = params["page"].to_i
      if page > MAX_PAGE_NUM
        raise BadRequestSearchError, "Page value #{page} is too high"
      end
      page == 0 ? 0 : search_page_size(params) * (page - 1)
    end

    def search_page_size(params)
      #TODO: raise error for invalid value, a la validate_field_params
      size = params["page_size"]
      if size.to_s == '0'
        0
      elsif size.to_i == 0
        DEFAULT_PAGE_SIZE
      elsif size.to_i > MAX_PAGE_SIZE
        MAX_PAGE_SIZE
      else
        size.to_i
      end
    end

    def wrap_results(result, params)
      {
        'count' => result['hits']['total'],
        'start' => search_offset(params),
        'limit' => search_page_size(params),
        'docs' => format_results(result['hits']['hits'], params),
        'facets' => format_facets(result['aggregations'], get_facet_size(params))
      }
    end

    def format_results(results, params)
      results.map do |doc|
        if doc['_source'].present?
          doc['_source'].delete_if {|k,v| k =~ /^_type/}
          doc['_source'].merge!({'score' => doc['_score']})
          flatten_fields!(doc['_source'], params)
          doc['_source']
        else
          doc['fields'] || {}
        end
      end
    end

    def flatten_fields!(doc_source, params)
      # Elasticsearch 6 returns fields specified in the '_source' parameter
      # (which was the 'fields' parameter in ES 0.90) as objects when they
      # are given in dotted form, like 'sourceResource.title' (for example,
      # {"sourceResource": {"title": "x"}}) but ES 0.90 used to return them
      # in dotted form (for example, {"sourceResource.title": "x"}). We have
      # to "flatten" the result coming back from Elasticsearch to keep our
      # output consistent with what we've been delivering.
      if params['fields'].present?
        toplevel_keys = {}
        params['fields'].split(',').each do |field|
          accumulator = doc_source
          if field[/\./]
            toplevel_keys[field.split('.')[0]] = true
          end
          field.split('.').each do |part|
            accumulator = accumulator[part] rescue nil
          end
          if !accumulator.nil?
            doc_source[field] = accumulator
          end
        end
        toplevel_keys.keys.each {|k| doc_source.delete(k)}
        true
      else
        false
      end
    end

    def format_facets(facets, facet_size)
      return [] unless facets

      facet_types = {
        'date' => 'date_histogram',
        'keyword' => 'terms',
        'text' => 'terms',
        'geo_point' => 'geo_distance'
      }
      facet_keys = {
        'date' => 'entries',
        'keyword' => 'terms',
        'text' => 'terms',
        'geo_point' => 'ranges'
      }

      formatted = {}

      facets.each do |name, payload|

        facet_values = payload['buckets']
        actual_field = actual_field(name)
        modifier = facet_modifier(name)

        field = Schema.field(resource, actual_field, modifier)

        if field.date?

          facet_values.delete_if do |v|
            v['doc_count'] == 0 ||
              v['key'] == -377705116800000 ||
              v['key'] == 253370764800000
          end
          
          facet_values.each do |v|
            bucket_item_key = v.key?('from') ? 'from' : 'key'
            v['time'] =
              format_date_facet(v[bucket_item_key], modifier)
          end
        end

        if facet_size
          # trim this facet to the requested limit after it has been optionally re-sorted
          facet_values = facet_values.first(facet_size.to_i)
        end

        formatted[es0_compat_field(name)] = {
          '_type' => facet_types[field.type],
          facet_keys[field.type] => facet_values.map do |v|
            if field.type == 'date'
              {
                'time' => v['time'],
                'count' => v['doc_count']
              }
            elsif field.type == 'geo_point'
              {
                'from' => v['from'] || 0,
                'to' => v['to'] || 0,
                'count' => v['doc_count']
              }
            else
              {
                'term' => v['key'],
                'count' => v['doc_count']
              }
            end
          end.sort {|a, b| b['time'] <=> a['time']}  # reverse date order
          # ^^^ Although V1::Searchable::FacetOptions.options_for_date_histogram
          # specifies a descending facet sort order on the date, it doesn't
          # apply with our "decade" and "century" facet modifiers, which are
          # expressed to Elasticsdarch as a "ranges" query prarmeter; so we
          # still have to do this sort. At least the sort won't have anything
          # to do in the typical case.
        }

      end

      formatted
    end

    # Given a field name as returned by Elasticsearch under `facets', massage
    # the name to make sure it's formatted as it used to be under
    # Elasticsearch 0.90.
    #
    # So far, this applies only to the geographic coordinates facet, given the
    # modifier like ":42:-70".
    #
    def es0_compat_field(field_name)
      if field_name[/:/]
        field_name[/^(.*?):/, 1]
      else
        field_name
      end
    end

    def actual_field(field_name)
      if field_name[/:/]
        field_name[/^(.*?):/, 1]
      else
        field_name[/^(.*?)\.?(year|decade|century)?$/, 1]
      end
    end

    def facet_modifier(field_name)
      field_name[/^(.*?)\.?(year|decade|century)?$/, 2]
    end

    def format_date_facet(value, interval=nil)

      # Value is from ElasticSearch and it is in UTC milliseconds since the epoch
      formats = {
        'day' => '%F',
        'month' => '%Y-%m',
        'year' => '%Y',
        'century' => '%Y',
        'decade' => '%Y'
      }      

      # hack to work around ElasticSearch adjusting timezones and breaking our dates
      offset = 5 * 60 * 60 * 1000 #5 hours in milliseconds
      date = Time.at( (value+offset)/1000 ).to_date

      # Default to 'day' format (e.g. '1993-01-31')
      date.strftime(formats[interval] || '%F')
    end

    def validate_query_params(params)
      # Raises exception if any unrecognized search params are present. Query-based 
      # extensions (e.g: spatial.distance) are added here as well. Does not examine
      # contents of fields containing field names, such as sorting, facets, etc.
      invalid = params.keys - (BASE_QUERY_PARAMS + Schema.queryable_field_names(resource))
      if invalid.any?
        raise BadRequestSearchError, "Invalid field(s) specified in query: #{invalid.join(',')}"
      end
    end

    def validate_field_params(params)
      invalid = params['fields'].to_s.split(/,\s*/) - Schema.queryable_field_names(resource)
      if invalid.any?  
        raise BadRequestSearchError, "Invalid field(s) specified in fields parameter: #{invalid.join(',')}" 
      end
    end

    def fetch(ids)
      # Accepts an array of ids OR a string containing a comma-separated list
      # of ids
      ids = ids.split(/,\s*/) if ids.is_a?(String)

      fetches = search({'id' => ids.join(' OR '), 'page_size' => 50})

      found_ids = []
      docs = fetches['docs'].map do |doc|
        found_ids << doc['id']
        doc
      end
      misses = ids - found_ids
      if ids.size == 1 && misses.size == 1
        raise NotFoundSearchError, "Document not found"
      end
      misses.each do |id|
        docs << {'id' => id, 'error' => '404'}
      end

      {
        'docs' => docs,
        'count' => docs.size
      }
    end

    def get_facet_size(params)
      Searchable::FacetOptions.facet_size(params)
    end

    def json_ld_context
      JsonLd.context_for(resource)
    end

  end

end
