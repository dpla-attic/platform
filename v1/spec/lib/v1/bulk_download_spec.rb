require 'v1/repository'
require 'v1/bulk_download'

module V1

  describe BulkDownload do

    describe "#contributor_links" do
      let(:result) {
        {
          "total_rows" => 2,
          "offset" => 0,
          "rows" => [
            {
              "id" => "1",
              "key" => "Contributor1",
              "value" => nil,
              "doc" => {
                "_id" => "1",
                "_rev" => "1",
                "contributor" => "Contributor1",
                "last_updated" => "2014-06-17T15:42:27.532804",
                "file_path" => "http://rackspace/contributor1.gz",
                "file_size" => "100 kB"
              }
            },
            {
              "id" => "2",
              "key" => "Contributor2",
              "value" => nil,
              "doc" => {
                "_id" => "2",
                "_rev" => "1",
                "contributor" => "Contributor2",
                "last_updated" => "2014-06-17T15:42:27.532804",
                "file_path" => "http://rackspace/contributor2.gz",
                "file_size" => "100 kB"
              }
            }
          ]
        }
      }

      it "returns a hash with contributor names as keys and URLs as values" do
        Repository.stub(:get_bulk_download_docs_by_contributor) { result }
        expected_json = {
          "Contributor1" => "http://rackspace/contributor1.gz",
          "Contributor2" => "http://rackspace/contributor2.gz"
        }
        expect(subject.contributor_links).to eq expected_json
      end
      
    end

  end

end
