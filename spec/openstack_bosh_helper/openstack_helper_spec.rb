require "spec_helper"

describe OpenstackBoshHelper::OpenstackHelper , openstack_credentials:true do
  def auth_url
    key = ENV['OS_AUTH_URL']
    raise 'need to set OS_AUTH_URL environment variable' unless key
    key
  end

  def user_name
    key = ENV['OS_USERNAME']
    raise 'need to set OS_USERNAME environment variable' unless key
    key
  end

  def passwd
    key = ENV['OS_PASSWORD']
    raise 'need to set OS_PASSWORD environment variable' unless key
    key
  end

  def tenant_name
    key = ENV['OS_TENANT_NAME']
    raise 'need to set OS_TENANT_NAME environment variable' unless key
    key
  end

  def sys_credential
    credential={}
    credential[:auth_url] = auth_url
    credential[:user_name] = user_name
    credential[:passwd] = passwd
    credential[:tenant_name] = tenant_name
    return credential
  end

  before :all do
    described_class.config (sys_credential)
  end

  context 'create/list/remove security group lifecycle' do
    let (:test_sg_name) {'openstack-spec-security_group-test'}

    it 'could list security group after create one, and delete it later on' do
      sg = described_class.list_seg
      sg.should_not include(test_sg_name)

      described_class.add_seg(test_sg_name)
      sg = described_class.list_seg
      sg.should include(test_sg_name)

      described_class.delete_seg(test_sg_name)
      sg = described_class.list_seg
      sg.should_not include(test_sg_name)
    end

    it 'could add rule to security group base on predefined flavor' do
    end

  end

  context 'keypair upload/list/remove lifecycle' do
    let (:test_key_name) { 'openstack-spec-key-test' }

    before :all do
      cmd = %Q(echo -e  'y\n' \| ssh-keygen -t rsa -N '' -f /tmp/openstack-spec-key-test.key)
      %x{#{cmd}}
    end

    after :all do
      File.delete('/tmp/openstack-spec-key-test.key')
      File.delete('/tmp/openstack-spec-key-test.key.pub')
    end

    it 'could list_keys after uploading keypair using upload_key and delete uploaded key using delete_keypair' do
      key_pairs = described_class.list_keypair
      key_pairs.should_not include(test_key_name)

      described_class.upload_keypair(test_key_name, '/tmp/openstack-spec-key-test.key.pub')
      key_pairs = described_class.list_keypair
      key_pairs.should include(test_key_name)

      described_class.delete_keypair(test_key_name)
      key_pairs = described_class.list_keypair
      key_pairs.should_not include(test_key_name)
    end

    it 'should raise error when uploading key with none exist key-pair' do
       File.stub(:exist?).with('/tmp/somethingnotexist-nonesensestring').and_return(false)
       expect { described_class.upload_keypair('openstack_spec_key_test', '/tmp/somethingnotexist-nonesensestring')}.to raise_error
    end
  end
end
