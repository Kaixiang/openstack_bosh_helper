require 'fog'
require 'pp'

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

      # Keypair operation helpers
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
        @openstack.create_key_pair(key_name,  public_key)
      end

      def delete_keypair(key_name)
        raise "no openstack instance" if @openstack.nil?
        @openstack.delete_key_pair(key_name)
      end

      # Security Group operation helpers
      def list_seg
        raise "no openstack instance" if @openstack.nil?
        response = @openstack.list_security_groups
        keys = parse_hash_response(response.body, 'security_groups')
        keys.map { |k| k.fetch('name') }
      end

      def add_seg(seg_name)
        raise "no openstack instance" if @openstack.nil?
        @openstack.create_security_group(seg_name, 'security_group created by openstack_bosh_helper')
      end

      def delete_seg(seg_name)
        raise "no openstack instance" if @openstack.nil?
        @openstack.delete_security_group(seg_name_to_id(seg_name))
      end

      def seg_name_to_id(seg_name)
        response = @openstack.list_security_groups
        keys = parse_hash_response(response.body, 'security_groups')
        key = keys.detect { |k| k.fetch('name').eql?(seg_name) }
        return key.fetch('id')
      end

      # prepare security flavor for 
      def add_seg_rule(flavor)

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
