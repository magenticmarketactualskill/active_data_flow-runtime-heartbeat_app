# frozen_string_literal: true

require "active_data_flow"
require "rails"
require_relative "rails_heartbeat_app/version"
require_relative "rails_heartbeat_app/configuration"
require_relative "rails_heartbeat_app/engine"

module ActiveDataFlow
  module RailsHeartbeatApp
    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end
    end
  end
end
