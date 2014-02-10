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
    input (:identity_server) { ask ("the identity server usr for openstack") }
    input (:flavor_name) { ask ("the flavor name for the instance created") }
    input (:user_name) { ask ("the username to login openstack") }
    input (:user_pass) { ask ("the password to login openstack") }
    input (:tenant) { ask ("the project/tenant name for openstack") }
    input (:keypair_name) { ask ("keypair name used in openstack") }
    input (:keypair_private_path) { ask ("private keypair local path") }
    def gm
      yamhash={}
      YAML_OPTIONS.each do |option|
        yamhash["#{option}".to_sym]=input["#{option}".to_sym]
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
    input (:identity_server) { ask ("the identity server usr for openstack") }
    input (:user_name) { ask ("the username to login openstack") }
    input (:user_pass) { ask ("the password to login openstack") }
    input (:tenant) { ask ("the project/tenant name for openstack") }
    def prep
      begin
        #TODO MORE INPUT SANITY CHECK FOR ALL CMD PARAM INPUT
        #
        unless File.directory?(DEPLOYMENT_PATH)
          FileUtils.mkdir_p(DEPLOYMENT_PATH)
        end

        credential={}
        credential[:auth_url] = 'https://'+input[:identity_server]+':5001/v2.0'
        credential[:tenant_name] = input[:tenant]
        credential[:user_name] = input[:user_name]
        credential[:passwd] = input[:user_pass]

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

  end
end
