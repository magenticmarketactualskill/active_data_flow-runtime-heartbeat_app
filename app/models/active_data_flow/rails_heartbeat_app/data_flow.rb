# frozen_string_literal: true

module ActiveDataFlow
  module RailsHeartbeatApp
    class DataFlow < ApplicationRecord
      self.table_name = "data_flows"

      # Associations
      has_many :data_flow_runs,
               class_name: "ActiveDataFlow::RailsHeartbeatApp::DataFlowRun",
               foreign_key: :data_flow_id,
               dependent: :destroy

      # Validations
      validates :name, presence: true, uniqueness: true
      validates :run_interval, numericality: { greater_than: 0 }
      validates :last_run_status, inclusion: { in: %w[success failed], allow_nil: true }

      # Serialization
      serialize :configuration, JSON

      # Scopes
      scope :enabled, -> { where(enabled: true) }

      # Class Methods
      def self.due_to_run
        enabled.select do |flow|
          flow.last_run_at.nil? || (Time.current - flow.last_run_at) >= flow.run_interval
        end
      end

      # Instance Methods
      def trigger_run!
        FlowExecutor.execute(self)
      end

      def flow_class
        class_name = configuration.is_a?(Hash) ? configuration["class_name"] : configuration
        class_name.constantize
      end
    end
  end
end
