require_relative '../../lib/dpla'

describe Dpla do

  context "#get_api_role" do
    it "should return a valid api_role from YAML" do
      YAML.stub!(:load_file) { {'api_role' => Dpla::API_ROLE_SANDBOX}  }
      Dpla.get_api_role.should == Dpla::API_ROLE_SANDBOX
    end

    it "should raise exception when api_role is not found in config file" do
      YAML.stub!(:load_file) { {}  }
      expect {
        Dpla.get_api_role
      }.to raise_error /missing or invalid 'api_role'/i
    end

    it "should raise exception when api_role is found in config file but invalid" do
      YAML.stub!(:load_file) { {'api_role' => 'not a real api role'}  }
      expect {
        Dpla.get_api_role
      }.to raise_error /missing or invalid 'api_role'/i
    end
  end

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
