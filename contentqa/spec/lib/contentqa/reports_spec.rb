require 'contentqa/reports'

module Contentqa

  describe Reports do
    
    describe "#find_report_types" do

      it "retrieves report types" do
        report_types = Reports.find_report_types
        report_types.should_not be_empty
      end     

    end

    describe "#find_last_ingests" do

      it "sorts ingest records and takes the latest ingest" do
        data = [{'key' => 'apple', 'value' => '3'}, {'key' => 'apple', 'value' => '2'}, 
               {'key' => 'banana', 'value' => '2'}, {'key' => 'banana', 'value' => '1'}]
        Reports.stub(:find_providers) { data }
        sorted = Reports.find_last_ingests
        sorted.should have(2).items
        sorted.should include({'key' => 'apple', 'value' => '3'}, {'key' => 'banana', 'value' => '2'})
      end

    end

    describe "#request_options" do

      before(:each) do
        Reports.stub(:find_ingest).and_return({'provider'=>'fake_provider'}) 
      end

      it "sets options for regular view" do
        options = Reports.request_options('fake_id', 'sourceResource.format')
        options.should include({
          :startkey => ["fake_provider", "_"], 
          :endkey => ["fake_provider", "Z"],
          :reduce => false
        })
      end

      it "sets options for group view" do 
        options = Reports.request_options('fake_id', 'sourceResource.format_count')
        options.should include({
          :startkey => ["fake_provider", "_"], 
          :endkey => ["fake_provider", "Z"],
          :group_level => "2"
        })
      end

      it "sets options for global view" do 
        options = Reports.request_options('fake_id', 'sourceResource.format_count_global')
        options.should include({
          :group_level => "2"
        })

      end
    end

    describe "#request_view_name" do
      it "sets design view name" do
        Reports.request_view_name('dataProvider_count_global').should == "qa_reports/dataProvider"
        Reports.request_view_name('dataProvider_count').should == "qa_reports/dataProvider"
        Reports.request_view_name('dataProvider').should == "qa_reports/dataProvider"
      end
    end

    describe "#aggregate" do

      it "aggregates global request data" do
        data = {"rows"=>[
          {"key"=>["1", "__MISSING__"], "value"=>1}, 
          {"key"=>["2", "__MISSING__"], "value"=>1}, 
          {"key"=>["3", "text/xml"], "value"=>1}, 
          {"key"=>["A", "__MISSING__"], "value"=>1}, 
          {"key"=>["B", "text/xml"], "value"=>1}, 
          {"key"=>["b1", "Images"], "value"=>1} 
        ]}
        Reports.aggregate(data).should include({
          "__MISSING__" => 3,
          "text/xml" => 2, 
          "Images" => 1
        })
      end
    end

    describe "filter" do

      it "filters regular provider request data" do
        data = {"rows"=>[
          {"id"=>"A", "key"=>["fake_provider", "__MISSING__", "1"], "value"=>1}, 
          {"id"=>"B", "key"=>["fake_provider", "Books", "2"], "value"=>1}, 
          {"id"=>"C", "key"=>["fake_provider", "Books", "3"], "value"=>1}, 
          {"id"=>"D", "key"=>["fake_provider", "Images", "4"], "value"=>1},
        ]}
        Reports.filter(data, 'sourceResource.format').should include({
          "1" => "__MISSING__",
          "2" => "Books",
          "3" => "Books",
          "4" => "Images"
        })
      end

      it "filters group provider request data" do
        data = {"rows"=>[
          {"key"=>["fake_provider", "__MISSING__"], "value"=>1}, 
          {"key"=>["fake_provider", "Books"], "value"=>62}, 
          {"key"=>["fake_provider", "Film"], "value"=>480}
        ]}
        Reports.filter(data, 'sourceResource.format_count').should include({
          "__MISSING__"=>1, 
          "Books"=>62, 
          "Film"=>480
        })
      end
    end

  end

end
