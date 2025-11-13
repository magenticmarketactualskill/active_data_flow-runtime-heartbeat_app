# frozen_string_literal: true

module ActiveDataFlow
  module RailsHeartbeatApp
    class Configuration
      attr_accessor :authentication_enabled,
                    :authentication_token,
                    :ip_whitelisting_enabled,
                    :whitelisted_ips,
                    :endpoint_path

      def initialize
        @authentication_enabled = false
        @authentication_token = nil
        @ip_whitelisting_enabled = false
        @whitelisted_ips = []
        @endpoint_path = "/data_flows/heartbeat"
      end
    end
  end
end
