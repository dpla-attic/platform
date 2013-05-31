require 'v1/version'

module V1

  describe "VERSION" do

    it "should be formatted correctly" do
      VERSION.should match /^\d+\.\d+\.\d+$/
    end

  end

end
