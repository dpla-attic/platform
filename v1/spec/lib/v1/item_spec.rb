require 'v1/item'

module V1

  describe Item do

    it "should respond_to? search" do
      V1::Item.should respond_to :search
    end

  end

end
