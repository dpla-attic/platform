require 'v1/search_error'

module V1

  describe SearchError do

    it "subclasses StandardError" do
      expect(subject.is_a? StandardError).to be_true
    end
    
    it "returns the correct default .message()" do
      ex = SearchError.new
      expect(ex.message).to eq 'V1::SearchError'
    end

    it "handles an explicit message param" do
      ex = SearchError.new 'some error'
      expect(ex.message).to eq 'some error'
    end

  end

  describe BadRequestSearchError do
    it "handles an explicit message param" do
      # ensure that SearchError subclasses can handle single param, but just test one of them
      ex = BadRequestSearchError.new 'bad req error'
      expect(ex.message).to eq 'bad req error'
    end
    it "has the correct http_status" do
      expect(BadRequestSearchError.new.http_status).to eq 400
    end
  end

  describe UnauthorizedSearchError do
    it "has the correct http_status" do
      expect(UnauthorizedSearchError.new.http_status).to eq 401
    end
  end 

  describe RateLimitExceededSearchError do
    it "has the correct http_status" do
      expect(RateLimitExceededSearchError.new.http_status).to eq  403
    end
  end 

  describe NotFoundSearchError do
    it "has the correct http_status" do
      expect(NotFoundSearchError.new.http_status).to eq 404
    end
  end 

  describe NotAcceptableSearchError do
    it "has the correct http_status" do
      expect(NotAcceptableSearchError.new.http_status).to eq 406
    end
  end 

  describe InternalServerSearchError do
    it "has the correct http_status" do
      expect(InternalServerSearchError.new.http_status).to eq 500
    end
  end 

  describe ServiceUnavailableSearchError do
    it "has the correct http_status" do
      expect(ServiceUnavailableSearchError.new.http_status).to eq 503
    end
  end 

end
