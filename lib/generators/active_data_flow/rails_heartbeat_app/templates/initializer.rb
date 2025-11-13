# frozen_string_literal: true

# Configure ActiveDataFlow Rails Heartbeat App
ActiveDataFlow::RailsHeartbeatApp.configure do |config|
  # Enable/disable authentication (default: false)
  # config.authentication_enabled = true

  # Set authentication token (recommended: use environment variable)
  # config.authentication_token = ENV["HEARTBEAT_TOKEN"]

  # Enable/disable IP whitelisting (default: false)
  # config.ip_whitelisting_enabled = true

  # Set whitelisted IPs (supports CIDR notation)
  # config.whitelisted_ips = ["10.0.0.0/8", "172.16.0.0/12", "192.168.1.100"]

  # Set custom endpoint path (default: "/data_flows/heartbeat")
  # config.endpoint_path = "/data_flows/heartbeat"
end
