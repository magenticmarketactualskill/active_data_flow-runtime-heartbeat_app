# frozen_string_literal: true

module ActiveDataFlow
  module RailsHeartbeatApp
    class Engine < ::Rails::Engine
      isolate_namespace ActiveDataFlow::RailsHeartbeatApp

      config.generators do |g|
        g.test_framework :rspec
      end

      initializer "active_data_flow_rails_heartbeat_app.load_app_paths" do |app|
        app.config.paths.add "app/models", eager_load: true
        app.config.paths.add "app/controllers", eager_load: true
        app.config.paths.add "app/services", eager_load: true
      end
    end
  end
end
