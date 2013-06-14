require 'v1/search_engine/river'

module V1

  module SearchEngine

    module River

      describe River do

        describe "#river_endpoint" do
          it "returns correct value" do
            Config.stub(:search_endpoint) { 'server:9200' }
            subject.stub(:river_name) { 'danube' }
            expect(subject.river_endpoint).to eq 'server:9200/_river/danube'
          end
        end

      end

    end

  end

end

