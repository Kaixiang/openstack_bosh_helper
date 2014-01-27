require "spec_helper"

describe OpenstackBoshHelper::MicroboshDeployer do
  before :each do
    described_class.clear
    @yamhash = {
      :allocated_floating_ip => '1.1.1.1',
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
    described_class.generate_microbosh_yml

  end

end
