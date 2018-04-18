##
# Post usage measurements to Google Analytics using the Measurement Protocol.
# @see https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide
#
# Errors may be logged, but should be invisible to the end user.

require 'httparty'

module V1
  class GoogleAnalytics
    include HTTParty

    ##
    # @param request ActionDispatch::Request
    # @param results JSON
    # @param page_title String
    def self.track_items(request, results, page_title)
      return if results.is_a? SearchError
      begin
        parsed_results = JSON.parse(results)
        self.track_pageview(request, page_title)
        self.track_events(request, parsed_results, page_title, "View API Item")
      rescue Exception => e
        # Fail silently if there are any unexpected errors.
        Rails.logger.error("Attempt at Google Analytics tracking failed with "\
          "the following message: #{e.message}")
      end
    end

    ##
    # @param request ActionDispatch::Request
    # @param page_title String
    def self.track_pageview(request, page_title)
      data = { t: "pageview" }
      data[:dh] = request.host
      data[:dp] = request.fullpath # Includes request params
      data[:dt] = page_title
      data[:cid] = request.query_parameters[:api_key]

      path = self.single_path
      body = self.data_string(data)
      self.post_request(path, body)
    end

    ##
    # @param request ActionDispatch::Request
    # @param results Hash
    # @param page_title String
    # @param event String
    def self.track_events(request, results, page_title, event)
      path = self.batch_path
      body = self.event_data(request, results, page_title, event)
      self.post_request(path, body)
    end

    private

    ##
    # Google analytics POST path for a single measurement.
    def self.single_path
      "http://www.google-analytics.com/collect"
    end

    ##
    # Google analytics POST path for a batch (multiple measurements).
    def self.batch_path
      "http://www.google-analytics.com/batch"
    end


    ##
    # Make HTTP POST request
    #
    # @param path String
    # @param body String
    #
    def self.post_request(path, body)
      begin
        response = HTTParty.post(path, { body: body  })
        # TODO: Is this the correct data to add to the log? May be too verbose.
        Rails.logger.info("Google Analytics POST: #{response.request.uri} "\
          "#{response.request.raw_body}")
        Rails.logger.info("Google Analytics RESPONSE CODE: #{response.code}")
      rescue Exception => e
        Rails.logger.error("Google Analytics POST attempt failed with the "\
          "following message: #{e.message}")
      end
    end

    ##
    # Create a string of data to be used in a request body.
    # @param data Hash - keys and values specific to a single pageview, event, etc.
    # @return String
    def self.data_string(data)
      # Add required fields.
      data[:v] = "1"
      data[:tid] = Config.google_analytics_tid

      data.map{ |k, v| "#{k}=#{v}" }.join("&")
    end

    ##
    # @param results Hash
    # @param event String
    #
    # Create a single string of event data to be used in a request body.
    # There may be 0 to many events represented the return string,
    # corresponding to the number of docs in the results.
    # Each individual event is represented on its own line, as required by
    # the Measurement Protocol.
    def self.event_data(request, results, page_title, event)
      begin
        data_strings = results['docs'].map do |doc|
          provider = self.join_if_array(doc['provider']['name']) rescue ""
          data_provider = self.join_if_array(doc['dataProvider']) rescue ""
          id = self.join_if_array(doc['id']) rescue ""
          title = self.join_if_array(doc['sourceResource']['title']) rescue ""

          data = { t: "event" }
          data[:ec] = "#{event} : #{provider}"
          data[:ea] = data_provider
          data[:el] = "#{id} : #{title}"
          data[:dh] = request.host
          data[:dp] = request.fullpath # Includes request params
          data[:dt] = page_title
          data[:cid] = request.query_parameters[:api_key]

          self.data_string(data)
        end
        data_strings.join("\n")
      rescue
        # Fail silently if unable to parse results
      end
    end

    ##
    # @param String | Array
    # @return String
    def self.join_if_array(value)
      Array.wrap(value).join(", ")
    end
  end
end
