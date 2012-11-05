require 'v1/schema'

module V1

  describe Schema do

    context "Module constants" do

      describe "V1::Schema::ELASTICSEARCH_MAPPING" do
        it "is frozen" do
          expect(V1::Schema::ELASTICSEARCH_MAPPING.frozen?).to be_true
        end
        it "has the expected top level structure" do
          expect(V1::Schema::ELASTICSEARCH_MAPPING).to be_a Hash
          expect(V1::Schema::ELASTICSEARCH_MAPPING).to have_key :mappings
          expect(V1::Schema::ELASTICSEARCH_MAPPING[:mappings]).to have_key :item
          expect(V1::Schema::ELASTICSEARCH_MAPPING[:mappings][:item]).to have_key :properties
        end
      end

    end

    context "mapping methods" do
      let(:full_mapping) {
        {
          :mappings => {
            :item => {
              :properties => {
                :created => { :type => 'date' },
                :spatial => {
                  :properties => {
                    :city => { :type => 'string', :index => 'not_analyzed' }
                  }
                }
              }
            },
            :collection => {
              :properties => {
                :title => { :type => 'string' }
              }
            }
          }
        }
      }
      
      before(:each) do
        stub_const("V1::Schema::ELASTICSEARCH_MAPPING", full_mapping)
      end

      describe "#mapping" do
        it "defaults to returning entire item mapping" do
          expect(subject.mapping()).to eq full_mapping[:mappings]
        end

        it "returns entire mapping for a single type" do
          expect(
                 subject.mapping(:item)
                 ).to eq({
                           :created => { :type => 'date' },
                           :spatial => {
                             :properties => {
                               :city => { :type => 'string', :index => 'not_analyzed' }
                             }
                           }
                         })
        end

        it "returns the mapping for a single field as requested" do
          expect(subject.mapping(:item, :created)).to eq( {:type => 'date' } )
          expect(subject.mapping(:collection, :title)).to eq( {:type => 'string'} )
        end

        it "maps dotted names to nested hashes" do
          expect(
                 subject.mapping(:item, 'spatial.city')
                 ).to eq( {:type=>"string", :index=>"not_analyzed"} )
        end

        it "returns nil for non-existent types" do
          expect(subject.mapping(:itemx)).to eq nil
        end

        it "returns nil for non-existent fields" do
          expect(subject.mapping(:item, :non_existent_field_lol)).to eq nil
        end
      end

      describe "#item_mapping" do
        it "retrieves 'item' mapping by default" do
          expect(subject.item_mapping).to eq subject.mapping(:item)
        end
        it "delegates to mapping() with correct params" do
          foo_mapping = stub
          subject.should_receive(:mapping).with(:item, :foo) { foo_mapping }
          expect(subject.item_mapping(:foo)).to eq foo_mapping
        end
      end

    end
  end

end
