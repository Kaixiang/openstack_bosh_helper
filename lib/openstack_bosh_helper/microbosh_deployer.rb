require 'erb'

module OpenstackBoshHelper
  class MicroboshDeployer
    DEPLOYMENT_PATH = '/tmp/deployments/microbosh-openstack/mico_bosh.yml'

    class << self
      CONFIG_OPTIONS = [       
        :allocated_floating_ip,
        :net_id,
        :identity_server,
        :flavor_name,
        :user_name,
        :user_pass,
        :tenant,
        :keypair_name,
        :keypair_private_path,
        :stemcell,
      ] 

      YAML_OPTIONS = [       
        :allocated_floating_ip,
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
        unless (File.exist?(DEPLOYMENT_PATH) && File.exist?(stemcell))
          raise "deployment or stemcell not found"
        end
         
      end

      def get_template(template)
        File.expand_path("../../../templates/#{template}", __FILE__)
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
