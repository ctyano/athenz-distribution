#!/usr/bin/env ruby
# Rebuild the vendored, non-secret manifests from the existing Kustomize sources.
# Requires Kustomize and the same generated local files required by those sources.
require 'fileutils'
require 'open3'
require 'yaml'

root = File.expand_path('../../..', __dir__)
target = File.expand_path('../files/manifests', __dir__)
components = {
  'crypki' => %w[crypki-softhsm],
  'vault' => %w[vault],
  'core' => %w[athenz-db athenz-cli athenz-zms-server athenz-zts-server athenz-ui],
  'identityprovider' => %w[athenz-identityprovider],
  'workloads' => %w[athenz-authorizer athenz-authzenvoy athenz-authzwebhook athenz-authzproxy athenz-client],
  'oauth2' => %w[athenz-oauth2],
  'rustfs' => %w[rustfs],
  'syncer' => %w[athenz-zms-syncer]
}

FileUtils.rm_rf(target)
components.each do |phase, names|
  names.each do |name|
    source = File.join(root, 'kubernetes', name, 'kustomize')
    output, error, status = Open3.capture3('kustomize', 'build', source)
    abort "kustomize build #{source}: #{error}" unless status.success?
    YAML.load_stream(output).compact.each do |resource|
      # Private keys/certificates are supplied by the pki phase. Never vendor
      # Secret objects from a developer's generated kustomize/keys directory.
      next if %w[Secret Namespace].include?(resource['kind'])
      next if phase == 'vault' && resource['kind'] == 'ConfigMap'

      basename = "#{resource.fetch('kind').downcase}-#{resource.fetch('metadata').fetch('name')}.yaml"
      destination = File.join(target, phase, name, basename)
      FileUtils.mkdir_p(File.dirname(destination))
      File.write(destination, resource.to_yaml)
    end
  end
end

# The authorizer Deployment references two policy ConfigMaps defined in the
# sibling gRPC authorizer example, although its own Kustomization omits them.
# Include those tracked files so the Pod's ConfigMap volumes can be mounted.
policy_root = File.join(root, 'kubernetes', 'athenz-grpc-authorizer', 'policy')
{
  'authorizer-config' => { 'config.yaml' => 'envoy/config.yaml' },
  'authorizer-policy' => {
    'envoy.authz.rego' => 'envoy/envoy.authz.rego',
    'functions.rego' => 'envoy/functions.rego',
    'system_log.rego' => 'system.log.rego',
    'data.yaml' => 'envoy/data.yaml'
  }
}.each do |name, files|
  data = files.transform_values { |path| File.read(File.join(policy_root, path)) }
  resource = {
    'apiVersion' => 'v1', 'kind' => 'ConfigMap',
    'metadata' => { 'name' => name, 'namespace' => 'athenz' },
    'data' => data
  }
  destination = File.join(target, 'workloads', 'athenz-authorizer', "configmap-#{name}.yaml")
  File.write(destination, resource.to_yaml)
end
