require 'fog'

module OpenstackBoshHelper
  class OpenstackHelper
    class << self

      attr_accessor :auth_url, :user_name, :tenant_name, :passwd

      def config(credential)
        @auth_url = credential.fetch(:auth_url)
        @user_name = credential.fetch(:user_name)
        @tenant_name = credential.fetch(:tenant_name)
        @passwd = credential.fetch(:passwd)

        openstack_params = {
          :provider => "openstack",       
          :openstack_auth_url => @auth_url + '/tokens',
          :openstack_username => @user_name,
          :openstack_tenant => @tenant_name,
          :openstack_api_key => @passwd,
          :connection_options  => {}
        }
        @openstack = Fog::Compute.new(openstack_params)        
      end

      def list_keypair
        raise "no openstack instance" if @openstack.nil?
        response = @openstack.list_key_pairs
        keys = parse_hash_response(response.body, 'keypairs')
        keys.map { |k| k.fetch('keypair').fetch('name') }
      end

      def upload_keypair(key_name, key_path)
        raise "no openstack instance" if @openstack.nil?
        raise "no key_found in #{key_path}" unless File.exist?(key_path)
        public_key = File.read(key_path)
        response = @openstack.create_key_pair(:name => key_name, :public_key => public_key)
        puts response.body
      end

      def delete_keypair(key_name)
        raise "no openstack instance" if @openstack.nil?
      end

      private

      def parse_hash_response(hash, *keys)
        unless hash.empty?
          key = keys.detect { |k| hash.has_key?(k)}
          return hash[key] if key
        end
      end

    end
  end
end
