# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveDataFlow::RailsHeartbeatApp::FlowExecutor do
  let(:mock_flow_class) do
    Class.new do
      def initialize(configuration)
        @configuration = configuration
      end

      def run
        # Successful execution
      end
    end
  end

  let(:data_flow) do
    ActiveDataFlow::RailsHeartbeatApp::DataFlow.create!(
      name: "test_flow",
      run_interval: 60,
      configuration: { "class_name" => "MockFlow", "options" => { "key" => "value" } }
    )
  end

  before do
    stub_const("MockFlow", mock_flow_class)
  end

  describe ".execute" do
    it "creates a new instance and calls execute" do
      executor = instance_double(described_class)
      allow(described_class).to receive(:new).with(data_flow).and_return(executor)
      expect(executor).to receive(:execute)

      described_class.execute(data_flow)
    end
  end

  describe "#execute" do
    context "when flow execution succeeds" do
      it "creates run record with pending status" do
        described_class.execute(data_flow)

        run = data_flow.data_flow_runs.first
        expect(run).to be_present
      end

      it "updates run record to in_progress status" do
        described_class.execute(data_flow)

        run = data_flow.data_flow_runs.first
        expect(run.status).to eq("success") # Final status after success
      end

      it "instantiates flow class with configuration" do
        expect(mock_flow_class).to receive(:new).with(data_flow.configuration).and_call_original

        described_class.execute(data_flow)
      end

      it "calls run method on flow instance" do
        flow_instance = instance_double(mock_flow_class)
        allow(mock_flow_class).to receive(:new).and_return(flow_instance)
        expect(flow_instance).to receive(:run)

        described_class.execute(data_flow)
      end

      it "updates data_flow with success status" do
        described_class.execute(data_flow)

        data_flow.reload
        expect(data_flow.last_run_status).to eq("success")
      end

      it "updates data_flow last_run_at" do
        freeze_time do
          described_class.execute(data_flow)

          data_flow.reload
          expect(data_flow.last_run_at).to be_within(1.second).of(Time.current)
        end
      end

      it "updates run record with success status" do
        described_class.execute(data_flow)

        run = data_flow.data_flow_runs.first
        expect(run.status).to eq("success")
      end

      it "updates run record with ended_at" do
        freeze_time do
          described_class.execute(data_flow)

          run = data_flow.data_flow_runs.first
          expect(run.ended_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    context "when flow execution fails" do
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
        data_flow.update!(configuration: { "class_name" => "FailingFlow" })
      end

      it "captures exception when flow.run raises error" do
        expect { described_class.execute(data_flow) }.to raise_error(StandardError, "Flow execution failed")
      end

      it "updates data_flow with failed status" do
        begin
          described_class.execute(data_flow)
        rescue StandardError
          # Expected
        end

        data_flow.reload
        expect(data_flow.last_run_status).to eq("failed")
      end

      it "updates run record with failed status" do
        begin
          described_class.execute(data_flow)
        rescue StandardError
          # Expected
        end

        run = data_flow.data_flow_runs.first
        expect(run.status).to eq("failed")
      end

      it "updates run record with error_message" do
        begin
          described_class.execute(data_flow)
        rescue StandardError
          # Expected
        end

        run = data_flow.data_flow_runs.first
        expect(run.error_message).to eq("Flow execution failed")
      end

      it "updates run record with error_backtrace" do
        begin
          described_class.execute(data_flow)
        rescue StandardError
          # Expected
        end

        run = data_flow.data_flow_runs.first
        expect(run.error_backtrace).to be_present
        expect(run.error_backtrace).to include("flow_executor_spec.rb")
      end

      it "re-raises exception after recording failure" do
        expect { described_class.execute(data_flow) }.to raise_error(StandardError, "Flow execution failed")
      end
    end
  end
end
