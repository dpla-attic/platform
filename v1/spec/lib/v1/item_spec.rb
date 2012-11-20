require 'v1/item'

module V1

  describe Item do

    it "is searchable" do
      expect(subject).to respond_to :search
    end

  end

end


