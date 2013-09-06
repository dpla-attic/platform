require 'v1/searchable/sort'

module V1

  module Searchable

    describe Sort do      
      let(:search) { double.as_null_object }
      let(:resource) { 'testitem' }

      context "Constants" do

        describe "default_sort_order" do
          it "has the correct value" do
            expect(subject.default_sort_order).to eq 'asc'
          end
        end

        describe "valid_sort_orders" do
          it "has the correct value" do
            expect(subject.valid_sort_orders).to match_array %w( asc desc )
          end
        end

      end

      describe "#build_sort" do

        it "calls search.sort" do
          subject.stub(:build_sort_attributes) { double }
          search.should_receive(:sort)
          subject.build_sort(resource, search, double)
        end

      end

      describe "#sort_order" do

        it "supplies a default value" do
          expect(subject.sort_order( {'sort_order' => ''} )).to eq subject.default_sort_order
        end

        it "raises an exception for an invalid value" do
          expect {
            subject.sort_order( {'sort_order' => 'X'} )
          }.to raise_error BadRequestSearchError, /Invalid sort_order value: X/
        end

      end

      describe "#sort_by" do

        it "returns a valid, sortable field" do
          field = double(:sortable? => true, :sort => 'field')
          Schema.stub(:field) { field }
          expect(subject.sort_by(resource, 'id')).to eq field
        end
        
        it "raises a BadRequestSearchError on an invalid sort_by param" do
          Schema.stub(:field) { nil }
          expect  { 
            subject.sort_by(resource, 'some_invalid_field')
          }.to raise_error BadRequestSearchError, /invalid field.* sort_by parameter: some_invalid_field/i
        end

        it "raises a BadRequestSearchError on a non-sortable sort_by param" do
          Schema.stub(:field) { double(:sortable? => false) }
          expect  { 
            subject.sort_by(resource, 'some_analyzed_field')
          }.to raise_error BadRequestSearchError, /non-sortable field.* sort_by parameter: some_analyzed_field/i
        end

        it "raises a InternalServerSearchError on a multi_field sort that is missing its not_analyzed_field" do
          Schema.stub(:field) { double(:sortable? => true, :sort => 'multi_field', :not_analyzed_field => nil) }
          expect  { 
            subject.sort_by(resource, 'some_analyzed_field')
          }.to raise_error InternalServerSearchError, /multi_field sort attribute missing not_analyzed sibling/i
        end

      end

      describe "#build_sort_attributes" do

        it "raises an error trying to script sort on an analyzed field" do
          params = {'sort_by' => 'raw_title'}
          field = double(:name => 'raw_title', :analyzed? => true, :sort => 'script')
          subject.stub(:sort_by) { field }

          expect {
            subject.build_sort_attributes(resource, params)
          }.to raise_error /Cannot script-sort on analyzed field/
        end
        
        it "raises an error when sort_by_pin is passed but sort_by is not" do
          params = { 'sort_by_pin' => '41,-71' }
          expect{
            subject.build_sort_attributes(resource, params)
          }.to raise_error BadRequestSearchError, /Nonsense use of sort_by_pin/i
        end
        
        it "returns _score default when sort params are not present" do
          params = {}
          expect(
                 subject.build_sort_attributes(resource, params)
                 ).to eq({ '_score' => {'order' => 'desc'} })
        end

        it "uses default sort_order if no sort_order param present" do
          name = 'id'
          field = double(:name => name, :date? => false, :sortable? => true, :sort => 'field')
          subject.stub(:sort_by).with(resource, name) { field }
          params = {'sort_by' => name}
          expect(
                 subject.build_sort_attributes(resource, params)
                 ).to eq( {name => {'order' => subject.default_sort_order}} )
        end

        it "returns correct array values for geo_point types" do
          name = 'coordinates'
          params = {'sort_by' => name, 'sort_by_pin' => '41,-71', 'order' => 'asc'}
          field = double(:sort => 'geo_distance', :sortable? => true, :name => name)
          subject.stub(:sort_by).with(resource, name) { field }
          expect(
                 subject.build_sort_attributes(resource, params)
                 ).to eq({'_geo_distance' => { name => '41,-71', 'order' => 'asc' }})
        end

        it "returns correct array for script sort" do
          name = 'title'
          params = {'sort_by' => name}
          field = double(:name => name, :sort => 'script', :sortable? => true, :analyzed? => false)

          subject.stub(:sort_by).with(resource, name) { field }
          expect(
                 subject.build_sort_attributes(resource, params)
                 ).to eq( 
                         {
                           '_script' => {
                             'script' => "s='';foreach(val : doc['#{name}'].values) {s += val + ' '} s",
                             'type' => "string",
                             'order' => 'asc'
                           }
                         }
                         )

        end

        it "returns correct value for shadow sort" do
          name = 'sourceResource.title'
          params = {'sort_by' => name}
          field = double(:name => name, :sort => 'shadow', :sortable? => true ) #, :analyzed? => true

          subject.stub(:sort_by).with(resource, name) { field }
          expect(
                 subject.build_sort_attributes(resource, params)
                 ).to eq( 
                         { 'admin.sourceResource.title' => {'order' => 'asc'} }
                         )
          
        end

      end

    end

  end

end
