module OpenstackBoshHelper
  class MicroboshDeployer
    class << self
      CONFIG_OPTIONS = [       
        :allocated_floating_ip,
        :identity_server,
        :flavor_name,
        :user_name,
        :user_pass,
        :tenant,
        :keypair_name,
        :keypair_private_path,
        :manifest,
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
        :manifest,
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

      def init(input)
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
      end

    end
  end
end
