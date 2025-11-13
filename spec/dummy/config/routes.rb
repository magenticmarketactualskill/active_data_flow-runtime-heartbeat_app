# frozen_string_literal: true

Rails.application.routes.draw do
  mount ActiveDataFlow::RailsHeartbeatApp::Engine => "/"
end
