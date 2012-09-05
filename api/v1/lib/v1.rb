require 'v1/engine'
require 'v1/config'
require 'v1/search'

module V1
  puts "api/v1/lib/v1.rb getting evalled"

  def self.config
    V1::Config
  end

end
