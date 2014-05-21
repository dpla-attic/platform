require 'v1/json_ld'
require 'json'

module V1

  describe JsonLd do

    let(:resource) { 'item' }
    let(:path) { File.expand_path("../../../../lib/v1/json_ld_context/#{resource}.json", __FILE__) }

    context "#context_for" do
      
      it "returns the JSON LD context document" do
        expect(File.exists? path).to be_true, "test can't find: #{path}"
        expect(JsonLd.context_for(resource)).to eq File.read(path)
      end

      it "returns valid JSON" do
        expect {
          JSON.parse(JsonLd.context_for(resource))
        }.not_to raise_error
      end

      it "raises an error when requesting context for a resource that doesn't exist" do
        expect {
          JsonLd.context_for('/dev/null/fake-resource')
        }.to raise_error /Invalid resource requested/
      end

      context "actual JSON LD context files" do
        
        it "contain valid JSON for resource 'item'" do
          expect {
            JSON.parse(JsonLd.context_for('item'))
          }.not_to raise_error
        end

        it "contain valid JSON for resource 'collection'" do
          expect {
            JSON.parse(JsonLd.context_for('collection'))
          }.not_to raise_error
        end
        
      end
      
    end
    
  end

end
