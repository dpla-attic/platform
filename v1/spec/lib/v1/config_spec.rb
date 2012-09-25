require 'spec_helper'
require 'v1/config'

describe V1::Config do

  it "should have a search_endpoint attribute" do
    V1::Config.should respond_to :search_endpoint
  end

end
