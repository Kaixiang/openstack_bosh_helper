require 'erb'

module OpenstackBoshHelper

  class MicroboshDeployer
    class << self
      CONFIG_OPTIONS.each do |option|
        attr_accessor option
      end

      def clear
        CONFIG_OPTIONS.each do |option|
          self.instance_variable_set("@#{option}".to_sym, nil)
        end
      end

      def addconf(input)
        input.each do |option, value|
          self.instance_variable_set("@#{option}".to_sym, value)
        end
      end

      def generate_microbosh_yml
        YAML_OPTIONS.each do |option|
          if self.instance_variable_get("@#{option}".to_sym).nil?
             raise "#{option} not set"
          end
        end

        ERB.new(File.read(get_template("micro_bosh.yml.erb"))).result(binding)
      end

      def deploy_microbosh
        DEPLOY_OPTIONS.each do |option|
          if self.instance_variable_get("@#{option}".to_sym).nil?
             raise "#{option} not set"
          end
        end
        unless (File.exist?(File.join(DEPLOYMENT_PATH, 'micro_bosh.yml')) && File.exist?(stemcell))
          raise "deployment or stemcell not found"
        end
        system("bosh micro deployment #{DEPLOYMENT_PATH}")
        system("bosh micro deploy #{stemcell}")
      end

      def gen_keypair
        if File.exist?(File.join(DEPLOYMENT_PATH, 'bosh.key'))
          raise "keypair #{File.join(DEPLOYMENT_PATH, 'bosh.key')} already exist"
        end
        if File.exist?(File.join(DEPLOYMENT_PATH, 'bosh.key.pub'))
          raise "keypair #{File.join(DEPLOYMENT_PATH, 'bosh.key.pub')} already exist"
        end
        sh("ssh-keygen -t rsa -N \"\" -f #{File.join(DEPLOYMENT_PATH, 'bosh.key')}")
      end

      def upload_keypair
        unless File.exist?(File.join(DEPLOYMENT_PATH, 'bosh.key.pub'))
          raise "keypair #{File.join(DEPLOYMENT_PATH, 'bosh.key.pub')} not exist, generate key first"
        end
        raise "no auth provided, generate manifest first" unless auth_provided?
        OpenstackHelper.config(:auth_url => @identity_server, :user_name => @user_name, :passwd => @user_pass, :tenant_name => @tenant)
        if OpenstackHelper.list_keypair.include?('bosh')
          raise "there was already a key name bosh in openstack server"
        else
          OpenstackHelper.upload_keypair('bosh', File.join(DEPLOYMENT_PATH, 'bosh.key.pub'))
        end

      end

      def get_template(template)
        File.expand_path("../../../templates/#{template}", __FILE__)
      end

      private

      def auth_provided?
        @identity_server && @user_name && @user_pass && @tenant
      end

      def sh(command, options={})
        opts = options.dup
        # can only yield if we don't raise errors
        opts[:on_error] = :return if opts[:yield] == :on_false

        output = %x{#{command}}
          result = Result.new(command, output, $?.exitstatus)
          if result.failed?
            unless opts[:on_error] == :return
              raise Error.new(result.exit_status, command, output)
            end
            yield result if block_given? && opts[:yield] == :on_false
          else
            yield result if block_given?
          end
          result
      rescue Errno::ENOENT => e
        msg = "command not found: #{command}"
        raise Error.new(nil, command) unless opts[:on_error] == :return
        result = Result.new(command, msg, -1, true)
        yield result if block_given? && opts[:yield] == :on_false
        result
      end
    end

  end
end
