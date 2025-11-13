# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"

module ActiveDataFlow
  module RailsHeartbeatApp
    module Generators
      class InstallGenerator < Rails::Generators::Base
        include Rails::Generators::Migration

        source_root File.expand_path("templates", __dir__)

        def self.next_migration_number(dirname)
          next_migration_number = current_migration_number(dirname) + 1
          ActiveRecord::Migration.next_migration_number(next_migration_number)
        end

        def copy_migrations
          migration_template "create_data_flows.rb",
                             "db/migrate/create_data_flows.rb"
          migration_template "create_data_flow_runs.rb",
                             "db/migrate/create_data_flow_runs.rb"
        end

        def copy_initializer
          template "initializer.rb",
                   "config/initializers/active_data_flow_rails_heartbeat_app.rb"
        end
      end
    end
  end
end
