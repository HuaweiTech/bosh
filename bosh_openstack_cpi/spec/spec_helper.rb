require File.expand_path('../../../spec/shared_spec_helper', __FILE__)

require 'tmpdir'
require 'zlib'
require 'archive/tar/minitar'
include Archive::Tar

require 'cloud/openstack'

def mock_cloud_options
  {
    'plugin' => 'openstack',
    'properties' => {
      'openstack' => {
        'auth_url' => 'http://127.0.0.1:5000/v2.0',
        'username' => 'admin',
        'api_key' => 'nova',
        'tenant' => 'admin',
        'region' => 'RegionOne',
        'state_timeout' => 0.1,
        'wait_resource_poll_interval' => 3
      },
      'registry' => {
        'endpoint' => 'localhost:42288',
        'user' => 'admin',
        'password' => 'admin'
      },
      'agent' => {
        'foo' => 'bar',
        'baz' => 'zaz'
      }
    }
  }
end

def make_cloud(options = nil)
  Bosh::OpenStackCloud::Cloud.new(options || mock_cloud_options['properties'])
end

def mock_registry(endpoint = 'http://registry:3333')
  registry = double('registry', :endpoint => endpoint)
  Bosh::Registry::Client.stub(:new).and_return(registry)
  registry
end

def mock_cloud(options = nil)
  servers = double('servers')
  images = double('images')
  flavors = double('flavors')
  volumes = double('volumes')
  addresses = double('addresses')
  snapshots = double('snapshots')
  key_pairs = double('key_pairs')
  security_groups = double('security_groups')

  glance = double(Fog::Image)
  Fog::Image.stub(:new).and_return(glance)

  volume = double(Fog::Volume)
  volume.stub(:volumes).and_return(volumes)
  Fog::Volume.stub(:new).and_return(volume)

  openstack = double(Fog::Compute)

  openstack.stub(:servers).and_return(servers)
  openstack.stub(:images).and_return(images)
  openstack.stub(:flavors).and_return(flavors)
  openstack.stub(:volumes).and_return(volumes)
  openstack.stub(:addresses).and_return(addresses)
  openstack.stub(:snapshots).and_return(snapshots)
  openstack.stub(:key_pairs).and_return(key_pairs)
  openstack.stub(:security_groups).and_return(security_groups)

  Fog::Compute.stub(:new).and_return(openstack)

  yield openstack if block_given?

  Bosh::OpenStackCloud::Cloud.new(options || mock_cloud_options['properties'])
end

def mock_glance(options = nil)
  images = double('images')

  openstack = double(Fog::Compute)
  Fog::Compute.stub(:new).and_return(openstack)

  volume = double(Fog::Volume)
  Fog::Volume.stub(:new).and_return(volume)

  glance = double(Fog::Image)
  glance.stub(:images).and_return(images)

  Fog::Image.stub(:new).and_return(glance)

  yield glance if block_given?

  Bosh::OpenStackCloud::Cloud.new(options || mock_cloud_options['properties'])
end

def dynamic_network_spec
  {
    'type' => 'dynamic',
    'cloud_properties' => {
      'security_groups' => %w[default]
    }
  }
end

def manual_network_spec
  {
    'type' => 'manual',
    'cloud_properties' => {
      'security_groups' => %w[default],
      'net_id' => 'net'
    }
  }
end

def manual_network_without_netid_spec
  {
    'type' => 'manual',
    'cloud_properties' => {
      'security_groups' => %w[default],
    }
  }
end

def dynamic_network_with_netid_spec
  {
    'type' => 'dynamic',
    'cloud_properties' => {
      'security_groups' => %w[default],
      'net_id' => 'net'
    }
  }
end

def vip_network_spec
  {
    'type' => 'vip',
    'ip' => '10.0.0.1'
  }
end

def combined_network_spec
  {
    'network_a' => dynamic_network_spec,
    'network_b' => vip_network_spec
  }
end

def resource_pool_spec
  {
    'key_name' => 'test_key',
    'availability_zone' => 'foobar-1a',
    'instance_type' => 'm1.tiny'
  }
end

RSpec.configure do |config|
  config.before(:each) { Bosh::Clouds::Config.stub(:logger).and_return(double.as_null_object)  }
end
