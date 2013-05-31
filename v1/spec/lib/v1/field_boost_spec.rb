require 'v1/field_boost'

module V1

  describe FieldBoost do

    let(:field_boosts) {
      {
        "boosted_resource" => {
          "field1" => 2,
          #TODO: query on field2 with a field_boost defined only for field2.subfield2: we need to boost subfields
          "field2.subfield2" => 1.5
        }
      }
    }

    describe "#all" do
      it "should delegate to Config.dpla" do
        dpla_config = {}
        Config.should_receive(:dpla) { dpla_config }
        expect(subject.all).to eq dpla_config
      end
      
    end

    describe "#for_resource" do
      
      before(:each) do
        subject.stub(:all) { field_boosts }
      end

      it "returns empty hash when there are no field boosts for a resource" do
        resource = "unboosted_resource"
        expect(subject.for_resource(resource)).to eq({})
      end

      it "returns the expected hash of all field boosts defined for a resource" do
        resource = "boosted_resource"
        expect(subject.for_resource(resource)).to eq({"field1"=>2, "field2.subfield2"=>1.5})
      end
    
    end

    describe "#for_field" do
      
      before(:each) do
        subject.stub(:all) { field_boosts }
      end

      it "returns nil for unboosted field" do
        resource = "boosted_resource"
        field = "unboosted_field"
        expect(subject.for_field(resource, field)).to eq nil
      end
      it "returns correct value for boosted field" do
        resource = "boosted_resource"
        field = "field1"
        expect(subject.for_field(resource, field)).to eq 2
      end
    end

  end

end
