require 'v1/item'

module V1

  describe Item do

    it "defines the resource method correctly" do
      expect(subject).to respond_to :resource
      expect(subject.resource).to eq 'item'
    end

    it "is searchable" do
      expect(subject).to respond_to :search
    end

  end

end


