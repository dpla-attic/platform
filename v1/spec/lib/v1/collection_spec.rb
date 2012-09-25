require 'v1/collection'

module V1

  describe Collection do

    it "should respond_to? search" do
      V1::Collection.should respond_to :search
    end

  end

end
