require 'contentqa/reports'

module Contentqa

  describe Reports do
    
    describe "#find_report_types" do

      it "retrieves report types" do
        report_types = Reports.find_report_types
        report_types.should_not be_empty
      end

      it "sorts ingest records and takes the latest ingest" do
        data = [{'key' => 'apple', 'value' => '3'}, {'key' => 'apple', 'value' => '2'}, 
               {'key' => 'banana', 'value' => '2'}, {'key' => 'banana', 'value' => '1'}]
        Reports.stub(:find_providers) { data }
        sorted = Reports.find_last_ingests
        sorted.should have(2).items
        sorted.should include({'key' => 'apple', 'value' => '3'}, {'key' => 'banana', 'value' => '2'})
      end

    end

  end

end
