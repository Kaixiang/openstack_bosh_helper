require "spec_helper"

describe OpenstackBoshHelper::MicroboshDeployer do
  before :each do
    described_class.clear
    @yamhash = {
      :allocated_floating_ip => '1.1.1.1',
      :net_id => 'e87c690f-413b-4dcf-ac2b-5468a2df0524',
      :identity_server => 'https://pivotal-1.openstack.blueboxgrid.com:5001/v2.0',
      :flavor_name => 'm1.large',
      :user_name => 'admin',
      :user_pass => 'passwd',
      :tenant => 'project',
      :keypair_name => 'bosh',
      :keypair_private_path => '~/.ssh/bosh_key',
    }

  end

  it "should generate a microbosh yaml with all the parameters" do
    described_class.init(@yamhash)
    gen_yml = described_class.generate_microbosh_yml
    gen_hash = YAML::load(gen_yml)
    gen_hash.should include("resources" => {"persistent_disk"=>16384, "cloud_properties" => {"instance_type" => "m1.large"}})
    gen_hash.should include("network" => {"type"=>"dynamic", "vip"=>"1.1.1.1", "cloud_properties"=>{"net_id"=>"e87c690f-413b-4dcf-ac2b-5468a2df0524"}})
    gen_hash.should include("logging" => {"level"=>"DEBUG"})
    gen_hash.should include("cloud" => {
      "plugin"=>"openstack",
      "properties" => {
        "openstack" => {
          "auth_url" => "https://pivotal-1.openstack.blueboxgrid.com:5001/v2.0",
          "username"=>"admin",
          "api_key"=>"passwd",
          "tenant"=>"project",
          "default_security_groups"=>["ssh", "bosh"],
          "default_key_name"=>"bosh",
          "private_key"=>"~/.ssh/bosh_key"}
      }
    })
  end

  it "should raise error without init" do
    described_class.init({})
    expect{ described_class.generate_microbosh_yml }.to raise_error
  end
end
