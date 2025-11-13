# frozen_string_literal: true

ActiveDataFlow::RailsHeartbeatApp::Engine.routes.draw do
  post "/data_flows/heartbeat", to: "data_flows#heartbeat", as: :heartbeat
end
