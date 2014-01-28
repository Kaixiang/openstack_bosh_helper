require "mothership"
require "highline/import"
require 'fileutils'


module OpenstackBoshHelper
  class HelperCommand < Mothership

    DEPLOYMENT_PATH = '/tmp/deployments/microbosh-openstack/mico_bosh.yml'
    YAML_OPTIONS = [       
      :allocated_floating_ip,
      :net_id,
      :identity_server,
      :flavor_name,
      :user_name,
      :user_pass,
      :tenant,
      :keypair_name,
      :keypair_private_path,
    ] 

    DEPLOY_OPTIONS = [       
      :stemcell,
    ] 


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
      
      dirname = File.dirname(DEPLOYMENT_PATH)
      unless File.directory?(dirname)
        FileUtils.mkdir_p(dirname)
      end

      File.open(DEPLOYMENT_PATH, 'w') do |file| 
        file.write(OpenstackBoshHelper::MicroboshDeployer.generate_microbosh_yml)
      end
      puts "File generated #{DEPLOYMENT_PATH}"
    end

    desc "Deploy micro bosh with existing deployment manifest and stemcell"
    input (:stemcell) { ask ("the stemcell path used for micro bosh?") }
    def dm


    end

  end
end
