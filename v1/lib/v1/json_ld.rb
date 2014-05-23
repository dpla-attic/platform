module V1

  module JsonLd

    def self.context_for(resource)
      path = File.expand_path("../json_ld_context/#{resource}.json", __FILE__)
      raise "Invalid resource requested: '#{resource}'" unless File.exist?(path)
      File.read(path)
    end

  end

end
