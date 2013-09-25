module V1

  class SearchError < StandardError
    attr_reader :http_status

    def initialize(msg=nil)
      @msg = msg if msg
    end

    def to_s
      (@msg || self.class).to_s
    end

  end

  class BadRequestSearchError < SearchError
    def initialize(msg=nil)
      super
      @http_status = 400
    end
  end

  class UnauthorizedSearchError < SearchError
    def initialize(msg=nil)
      msg ||= 'Unauthorized: Missing, invalid or inactive api_key'
      super
      @http_status = 401
    end
  end

  class RateLimitExceededSearchError < SearchError
    def initialize(msg=nil)
      super
      @http_status = 403
    end
  end

  class NotFoundSearchError < SearchError
    def initialize(msg=nil)
      super
      @http_status = 404
    end
  end

  class NotAcceptableSearchError < SearchError
    def initialize(msg=nil)
      super
      @http_status = 406
    end
  end


  class InternalServerSearchError < SearchError
    def initialize(msg=nil)
      msg ||= 'Internal Server Error'
      super
      @http_status = 500
    end
  end

  class ServiceUnavailableSearchError < SearchError
    def initialize(msg=nil)
      msg ||= 'Service Temporarily Unavailable'
      super
      @http_status = 503
    end
  end

end
