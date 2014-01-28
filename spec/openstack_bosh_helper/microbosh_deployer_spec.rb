require "spec_helper"

describe OpenstackBoshHelper::MicroboshDeployer do
  context 'to generate micorbosh yaml' do
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
      described_class.addconf(@yamhash)
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

    it "should raise error without parameters init" do
      described_class.addconf({})
      expect{ described_class.generate_microbosh_yml }.to raise_error
    end
  end

  context 'to deploy microbosh with stemcells and yaml file' do
    before :each do
      described_class.clear
      @deployhash = {
        'stemcell' => '/tmp/stemcell-openstack.tgz'
      }
    end

    it "should raise error without parameters init" do
      described_class.addconf({})
      expect{ described_class.deploy_microbosh }.to raise_error
    end

    it "should shell out to bosh deploy given parameters" do
      described_class.addconf(@deployhash)
      File.stub(:exist?) { true }
      described_class.should_receive(:sh).with("bosh micro deployment #{OpenstackBoshHelper::MicroboshDeployer::DEPLOYMENT_PATH}")
      described_class.should_receive(:sh).with("bosh micro deploy #{@deployhash['stemcell']}")
      described_class.deploy_microbosh
    end

    it "raise error if manifiest or stemcell file not exist" do
      described_class.addconf(@deployhash)
      File.stub(:exist?) { false }
      expect{ described_class.deploy_microbosh }.to raise_error
    end
  end

  context 'to generate sshkey-pair in deployment_path directory' do
    it "should shell out generate ssh-key to deployment_path" do
      File.stub(:exist?) { false }
      described_class.should_receive(:sh).with("ssh-keygen -t rsa -N \"\" -f #{File.join(OpenstackBoshHelper::MicroboshDeployer::DEPLOYMENT_PATH, 'bosh.key')}")
      described_class.gen_keypair
    end

    it "raise error when all keypair exist" do
      File.stub(:exist?).with(File.join(OpenstackBoshHelper::MicroboshDeployer::DEPLOYMENT_PATH, 'bosh.key')).and_return(true)
      File.stub(:exist?).with(File.join(OpenstackBoshHelper::MicroboshDeployer::DEPLOYMENT_PATH, 'bosh.key.pub')).and_return(true)
      expect{ described_class.gen_keypair }.to raise_error
    end

    it "raise error when private keypair exist" do
      File.stub(:exist?).with(File.join(OpenstackBoshHelper::MicroboshDeployer::DEPLOYMENT_PATH, 'bosh.key')).and_return(true)
      File.stub(:exist?).with(File.join(OpenstackBoshHelper::MicroboshDeployer::DEPLOYMENT_PATH, 'bosh.key.pub')).and_return(false)
      expect{ described_class.gen_keypair }.to raise_error
    end

    it "raise error when pub key exist" do
      File.stub(:exist?).with(File.join(OpenstackBoshHelper::MicroboshDeployer::DEPLOYMENT_PATH, 'bosh.key')).and_return(false)
      File.stub(:exist?).with(File.join(OpenstackBoshHelper::MicroboshDeployer::DEPLOYMENT_PATH, 'bosh.key.pub')).and_return(true)
      expect{ described_class.gen_keypair }.to raise_error
    end
  end

end
