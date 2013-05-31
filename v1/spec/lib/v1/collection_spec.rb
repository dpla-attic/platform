require 'v1/collection'

module V1

  describe Collection do

    it "defines the resource method correctly" do
      expect(subject).to respond_to :resource
      expect(subject.resource).to eq 'collection'
    end

    it "respond_to? search" do
      expect(subject).to respond_to :search
    end

  end

end
