require 'v1/search_engine'

module V1

  module SearchEngine

    describe SearchEngine do
      before(:each) do
        # No need to check this inside unit tests
        subject.stub(:endpoint_config_check)
      end
      
    end

  end

end
