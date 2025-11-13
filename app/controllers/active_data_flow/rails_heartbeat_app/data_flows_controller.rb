# frozen_string_literal: true

module ActiveDataFlow
  module RailsHeartbeatApp
    class DataFlowsController < ActionController::Base
      skip_before_action :verify_authenticity_token
      before_action :authenticate_heartbeat!
      before_action :check_ip_whitelist!

      def heartbeat
        flows = DataFlow.due_to_run.lock("FOR UPDATE SKIP LOCKED")
        triggered_count = 0

        flows.each do |flow|
          FlowExecutor.execute(flow)
          triggered_count += 1
        rescue => e
          Rails.logger.error("Flow execution failed: #{e.message}")
          # Continue with next flow
        end

        render json: {
          flows_due: flows.count,
          flows_triggered: triggered_count,
          timestamp: Time.current
        }
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def authenticate_heartbeat!
        return unless ActiveDataFlow::RailsHeartbeatApp.config.authentication_enabled

        token = request.headers["X-Heartbeat-Token"]
        expected = ActiveDataFlow::RailsHeartbeatApp.config.authentication_token

        unless ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected.to_s)
          log_authentication_failure
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      def check_ip_whitelist!
        return unless ActiveDataFlow::RailsHeartbeatApp.config.ip_whitelisting_enabled

        whitelist = ActiveDataFlow::RailsHeartbeatApp.config.whitelisted_ips
        source_ip = request.remote_ip

        unless whitelist.include?(source_ip)
          log_ip_rejection(source_ip)
          render json: { error: "Forbidden" }, status: :forbidden
        end
      end

      def log_authentication_failure
        Rails.logger.warn(
          "Heartbeat authentication failed from #{request.remote_ip} at #{Time.current}"
        )
      end

      def log_ip_rejection(ip)
        Rails.logger.warn(
          "Heartbeat IP whitelist rejection: #{ip} at #{Time.current}"
        )
      end
    end
  end
end
