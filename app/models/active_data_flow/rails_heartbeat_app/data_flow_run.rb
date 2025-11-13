# frozen_string_literal: true

module ActiveDataFlow
  module RailsHeartbeatApp
    class DataFlowRun < ApplicationRecord
      self.table_name = "data_flow_runs"

      # Associations
      belongs_to :data_flow,
                 class_name: "ActiveDataFlow::RailsHeartbeatApp::DataFlow",
                 foreign_key: :data_flow_id

      # Validations
      validates :status, inclusion: { in: %w[pending in_progress success failed] }
      validates :started_at, presence: true

      # Instance Methods
      def duration
        return nil unless ended_at
        ended_at - started_at
      end

      def success?
        status == "success"
      end

      def failed?
        status == "failed"
      end
    end
  end
end
