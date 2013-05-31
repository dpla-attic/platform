require 'dpla'

describe Dpla do

  context "#check_config" do

    it "should return false if it cannot find a given config file" do
      File.stub(:exists? ) {false}
      Dpla.stub!(:puts)  #suppress stdout, basically
      check = Dpla.check_config( __FILE__, %w( config/file.yml ) )
      check.should == false
    end

    it "should return true if it can find a given config file" do
      File.stub(:exists? ) {true}
      check = Dpla.check_config( __FILE__, %w( config/file.yml ) )
      check.should == true
    end

  end

end
