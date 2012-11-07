require 'v1/standard_dataset'

module V1
  describe StandardDataset do
    context "importing and indexing " do  
      describe "#recreate_index!" do
        
        it "does not raise exception when import results import successfully" do
          StandardDataset.should_receive(:source_item_count)  { 50 }
          StandardDataset.should_receive(:indexed_item_count) { 50 }
          expect { subject.recreate_index! }.to_not raise_error
        end
        
        it "raises exception when import results contain errors" do
          StandardDataset.should_receive(:source_item_count)  { 50 }
          StandardDataset.should_receive(:indexed_item_count) { 49 }
          expect { subject.recreate_index! }.to raise_error
        end
      end

    end
  end
end
