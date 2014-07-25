require_relative 'repository'

module V1

  module BulkDownload

    def self.contributor_links
      response = Repository.get_bulk_download_docs_by_contributor
      rows = response.fetch('rows', {})
      return rows.inject({}) do |hash, row|
        hash[row['key']] = row['doc']['file_path']
        hash
      end 
    end

  end

end
