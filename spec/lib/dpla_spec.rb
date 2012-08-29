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
end
