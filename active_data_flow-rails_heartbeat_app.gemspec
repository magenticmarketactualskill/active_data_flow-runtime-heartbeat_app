# frozen_string_literal: true

require_relative "lib/active_data_flow/rails_heartbeat_app/version"

Gem::Specification.new do |spec|
  spec.name = "active_data_flow-rails_heartbeat_app"
  spec.version = ActiveDataFlow::RailsHeartbeatApp::VERSION
  spec.authors = ["ActiveDataFlow Team"]
  spec.email = ["team@activedataflow.dev"]

  spec.summary = "Rails engine for heartbeat-triggered DataFlow execution"
  spec.description = "Provides database-backed, HTTP-triggered synchronous execution of ActiveDataFlow DataFlows in Rails applications"
  spec.homepage = "https://github.com/activedataflow/active_data_flow"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{app,config,db,lib}/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "active_data_flow", "~> 0.1"
  spec.add_dependency "rails", ">= 6.0"

  # Development dependencies
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "sqlite3", "~> 1.4"
  spec.add_development_dependency "rubocop", "~> 1.50"
end
