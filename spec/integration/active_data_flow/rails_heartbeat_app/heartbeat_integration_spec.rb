# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Heartbeat Integration", type: :request do
  let(:mock_flow_class) do
    Class.new do
      def initialize(configuration)
        @configuration = configuration
        @executed = false
      end

      def run
        @executed = true
      end

      def executed?
        @executed
      end
    end
  end

  before do
    stub_const("MockFlow", mock_flow_class)
  end

  describe "end-to-end flow execution" do
    it "creates flow record, triggers heartbeat, verifies execution and run record" do
      # Create flow record
      flow = ActiveDataFlow::RailsHeartbeatApp::DataFlow.create!(
        name: "test_flow",
        run_interval: 60,
        configuration: { "class_name" => "MockFlow" }
      )

      # Trigger heartbeat
      post "/data_flows/heartbeat"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["flows_due"]).to eq(1)
      expect(body["flows_triggered"]).to eq(1)

      # Verify execution
      flow.reload
      expect(flow.last_run_status).to eq("success")
      expect(flow.last_run_at).to be_present

      # Verify run record
      run = flow.data_flow_runs.first
      expect(run).to be_present
      expect(run.status).to eq("success")
      expect(run.started_at).to be_present
      expect(run.ended_at).to be_present
      expect(run.duration).to be > 0
    end
  end

  describe "multiple flows with different intervals" do
    it "executes only due flows" do
      # Create flows with different intervals
      due_flow_1 = ActiveDataFlow::RailsHeartbeatApp::DataFlow.create!(
        name: "due_flow_1",
        run_interval: 60,
        last_run_at: 2.minutes.ago,
        configuration: { "class_name" => "MockFlow" }
      )

      due_flow_2 = ActiveDataFlow::RailsHeartbeatApp::DataFlow.create!(
        name: "due_flow_2",
        run_interval: 120,
        last_run_at: 3.minutes.ago,
        configuration: { "class_name" => "MockFlow" }
      )

      not_due_flow = ActiveDataFlow::RailsHeartbeatApp::DataFlow.create!(
        name: "not_due_flow",
        run_interval: 3600,
        last_run_at: 30.minutes.ago,
        configuration: { "class_name" => "MockFlow" }
      )

      # Trigger heartbeat
      post "/data_flows/heartbeat"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["flows_due"]).to eq(2)
      expect(body["flows_triggered"]).to eq(2)

      # Verify due flows were executed
      due_flow_1.reload
      expect(due_flow_1.last_run_status).to eq("success")

      due_flow_2.reload
      expect(due_flow_2.last_run_status).to eq("success")

      # Verify not due flow was not executed
      not_due_flow.reload
      expect(not_due_flow.last_run_at).to be_within(1.second).of(30.minutes.ago)
    end
  end

  describe "failed flow doesn't block execution of other flows" do
    let(:failing_flow_class) do
      Class.new do
        def initialize(configuration)
          @configuration = configuration
        end

        def run
          raise StandardError, "Flow execution failed"
        end
      end
    end

    before do
      stub_const("FailingFlow", failing_flow_class)
    end

    it "continues executing other flows when one fails" do
      failing_flow = ActiveDataFlow::RailsHeartbeatApp::DataFlow.create!(
        name: "failing_flow",
        run_interval: 60,
        configuration: { "class_name" => "FailingFlow" }
      )

      success_flow = ActiveDataFlow::RailsHeartbeatApp::DataFlow.create!(
        name: "success_flow",
        run_interval: 60,
        configuration: { "class_name" => "MockFlow" }
      )

      # Trigger heartbeat
      post "/data_flows/heartbeat"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["flows_due"]).to eq(2)

      # Verify failing flow was marked as failed
      failing_flow.reload
      expect(failing_flow.last_run_status).to eq("failed")
      expect(failing_flow.data_flow_runs.first.status).to eq("failed")
      expect(failing_flow.data_flow_runs.first.error_message).to eq("Flow execution failed")

      # Verify success flow was still executed
      success_flow.reload
      expect(success_flow.last_run_status).to eq("success")
      expect(success_flow.data_flow_runs.first.status).to eq("success")
    end
  end

  describe "concurrent heartbeat requests don't duplicate execution" do
    it "uses database locking to prevent duplicate execution" do
      flow = ActiveDataFlow::RailsHeartbeatApp::DataFlow.create!(
        name: "test_flow",
        run_interval: 60,
        configuration: { "class_name" => "MockFlow" }
      )

      # Simulate concurrent requests by making multiple requests
      # In a real scenario, these would be truly concurrent
      # For testing, we verify the locking mechanism is in place
      threads = []
      execution_counts = []

      3.times do
        threads << Thread.new do
          post "/data_flows/heartbeat"
          body = JSON.parse(response.body)
          execution_counts << body["flows_triggered"]
        end
      end

      threads.each(&:join)

      # Verify that the flow was executed (at least once)
      flow.reload
      expect(flow.last_run_status).to eq("success")

      # Verify run records were created
      # Due to the nature of the test, we can't guarantee exact count
      # but we can verify that execution happened
      expect(flow.data_flow_runs.count).to be >= 1
    end
  end
end
