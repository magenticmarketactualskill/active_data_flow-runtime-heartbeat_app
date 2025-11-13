# frozen_string_literal: true

module ActiveDataFlow
  module RailsHeartbeatApp
    class FlowExecutor
      def self.execute(data_flow)
        new(data_flow).execute
      end

      def initialize(data_flow)
        @data_flow = data_flow
        @run = nil
      end

      def execute
        create_run_record
        instantiate_and_run_flow
        mark_success
      rescue => e
        mark_failure(e)
        raise
      end

      private

      attr_reader :data_flow, :run

      def create_run_record
        @run = data_flow.data_flow_runs.create!(
          status: "pending",
          started_at: Time.current
        )
        @run.update!(status: "in_progress")
      end

      def instantiate_and_run_flow
        flow_class = data_flow.flow_class
        flow_instance = flow_class.new(data_flow.configuration)
        flow_instance.run
      end

      def mark_success
        data_flow.update!(
          last_run_at: Time.current,
          last_run_status: "success"
        )
        run.update!(
          status: "success",
          ended_at: Time.current
        )
      end

      def mark_failure(exception)
        data_flow.update!(
          last_run_at: Time.current,
          last_run_status: "failed"
        )
        run.update!(
          status: "failed",
          ended_at: Time.current,
          error_message: exception.message,
          error_backtrace: exception.backtrace.join("\n")
        )
      end
    end
  end
end
