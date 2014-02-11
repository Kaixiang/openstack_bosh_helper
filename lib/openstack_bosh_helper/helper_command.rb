require 'mothership'
require 'highline/import'
require 'fileutils'


module OpenstackBoshHelper
  class HelperCommand < Mothership

    SEC_BOSH_NAME = { :name => 'bosh', :flavor => OpenstackBoshHelper::BOSH_FLAVOR, 
                      :desc => 'security group created by openstack_bosh_helper, used for micro_bosh' }
    SEC_SSH_NAME = { :name => 'ssh', :flavor => OpenstackBoshHelper::SSH_FLAVOR,
                     :desc => 'security group created by openstack_bosh_helper, used for ssh' }
    SEC_CF_PRI_NAME = { :name => 'cf-private', :flavor => OpenstackBoshHelper::CF_PRI_FLAVOR,
                        :desc => 'security group created by openstack_bosh_helper, used for CF internal network' }
    SEC_CF_PUB_NAME = { :name => 'cf-public', :flavor => OpenstackBoshHelper::CF_PUB_FLAVOR,
                        :desc => 'security group created by openstack_bosh_helper, used for CF external network' }

    SECS_ALL = [SEC_BOSH_NAME, SEC_SSH_NAME, SEC_CF_PRI_NAME, SEC_CF_PUB_NAME]

    option :help, :desc => "Show command usage", :alias => "-h",
      :default => false

    desc "Show Help"
    input :command, :argument => :optional
    def help
      if name = input[:command]
        if cmd = @@commands[name.gsub("-", "_").to_sym]
          Mothership::Help.command_help(cmd)
        else
          unknown_command(name)
        end
      else
        Mothership::Help.basic_help(@@commands, @@global)
      end
    end

    desc "Generate microbosh manifest"
    input (:allocated_floating_ip) { ask ("the floating ip for the microbosh?") }
    input (:net_id) { ask ("the network id for openstack") }
    input (:identity_server) { hint; ask ("the identity server usr for openstack") }
    input (:user_name) { hint; ask ("the username to login openstack") }
    input (:user_pass) { hint; ask ("the password to login openstack") }
    input (:tenant) { hint; ask ("the project/tenant name for openstack") }
    input (:flavor_name) { 'm1.large' }
    input (:keypair_name) { 'bosh' }
    input (:keypair_private_path) { File.join(DEPLOYMENT_PATH, 'bosh.key') }
    def gm
      yamhash={}
      YAML_OPTIONS.each do |option|
        case option
        when :identity_server
          yamhash["#{option}".to_sym] = auth_url(input)
        when :tenant
          yamhash["#{option}".to_sym] = tenant_name(input)
        when :user_name
          yamhash["#{option}".to_sym] = user_name(input)
        when :user_pass
          yamhash["#{option}".to_sym] = passwd(input)
        else
          yamhash["#{option}".to_sym]=input["#{option}".to_sym]
        end
      end
      OpenstackBoshHelper::MicroboshDeployer.addconf(yamhash)

      unless File.directory?(DEPLOYMENT_PATH)
        FileUtils.mkdir_p(DEPLOYMENT_PATH)
      end

      File.open(File.join(DEPLOYMENT_PATH, 'micro_bosh.yml'), 'w') do |file|
        file.write(OpenstackBoshHelper::MicroboshDeployer.generate_microbosh_yml)
      end
      puts "File generated #{File.join(DEPLOYMENT_PATH, 'mico_bosh.yml')}"
    end

    desc "Deploy micro bosh with existing deployment manifest and stemcell"
    input (:stemcell) { ask ("the stemcell path used for micro bosh?") }
    def dm
      deployhash={}
      DEPLOY_OPTIONS.each do |option|
        deployhash["#{option}".to_sym]=input["#{option}".to_sym]
      end
      begin
        OpenstackBoshHelper::MicroboshDeployer.addconf(deployhash)
        OpenstackBoshHelper::MicroboshDeployer.deploy_microbosh
      rescue StandardError => e
        puts "Errored during deploy: #{e}"
      end
    end

    desc "Generate keypair to default deployment Path"
    def keygen
      begin
        unless File.directory?(DEPLOYMENT_PATH)
          FileUtils.mkdir_p(DEPLOYMENT_PATH)
        end

        OpenstackBoshHelper::MicroboshDeployer.gen_keypair
        puts "key generated #{File.join(DEPLOYMENT_PATH, 'bosh.key')}"
      rescue StandardError => e
        puts "Errored during keygen: #{e}"
      end
    end

    desc "Prepair keypair and security group in openstack"
    input (:identity_server) { hint; ask ("the identity server usr for openstack") }
    input (:user_name) { hint; ask ("the username to login openstack") }
    input (:user_pass) { hint; ask ("the password to login openstack") }
    input (:tenant) { hint; ask ("the project/tenant name for openstack") }
    def prep
      begin
        unless File.directory?(DEPLOYMENT_PATH)
          FileUtils.mkdir_p(DEPLOYMENT_PATH)
        end

        credential={}
        credential[:auth_url] = auth_url(input)
        credential[:tenant_name] = tenant_name(input)
        credential[:user_name] = user_name(input)
        credential[:passwd] = passwd(input)

        OpenstackBoshHelper::OpenstackHelper.config(credential)

        puts "Uploading keypair bosh in #{File.join(DEPLOYMENT_PATH, 'bosh.key.pub')}"
        OpenstackBoshHelper::OpenstackHelper.upload_keypair('bosh', File.join(OpenstackBoshHelper::DEPLOYMENT_PATH, 'bosh.key.pub'))

        SECS_ALL.each do |sec|
          puts "Creating Security Group #{sec[:name]}"
          OpenstackBoshHelper::OpenstackHelper.add_seg(sec[:name])
          puts "Applying Security rule for #{sec[:name]}"
          OpenstackBoshHelper::OpenstackHelper.add_seg_rule(sec[:name], sec[:flavor])
        end

      rescue StandardError => e
        puts "Errored during Openstack keypair/sec group Prepare: #{e}"
      end

    end

    private

    def auth_url(input)
      key = ENV['OS_AUTH_URL']
      key = 'https://'+input[:identity_server]+':5001/v2.0' unless key
      key
    end

    def user_name(input)
      key = ENV['OS_USERNAME']
      key = input[:user_name] unless key
      key
    end

    def passwd(input)
      key = ENV['OS_PASSWORD']
      key = input[:user_pass] unless key
      key
    end

    def tenant_name(input)
      key = ENV['OS_TENANT_NAME']
      key = input[:tenant] unless key
      key
    end

    def hint
        puts "[HINT] source the openstack rc file to avoid input every time"
    end

  end
end
