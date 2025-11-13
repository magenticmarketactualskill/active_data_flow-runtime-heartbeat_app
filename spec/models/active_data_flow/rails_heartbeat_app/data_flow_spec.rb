# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveDataFlow::RailsHeartbeatApp::DataFlow, type: :model do
  describe "validations" do
    it "validates presence of name" do
      flow = described_class.new(run_interval: 60)
      expect(flow).not_to be_valid
      expect(flow.errors[:name]).to include("can't be blank")
    end

    it "validates uniqueness of name" do
      described_class.create!(name: "test_flow", run_interval: 60)
      duplicate = described_class.new(name: "test_flow", run_interval: 60)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    it "validates run_interval is greater than 0" do
      flow = described_class.new(name: "test_flow", run_interval: 0)
      expect(flow).not_to be_valid
      expect(flow.errors[:run_interval]).to include("must be greater than 0")
    end

    it "validates last_run_status inclusion" do
      flow = described_class.new(name: "test_flow", run_interval: 60, last_run_status: "invalid")
      expect(flow).not_to be_valid
      expect(flow.errors[:last_run_status]).to include("is not included in the list")
    end

    it "allows nil last_run_status" do
      flow = described_class.new(name: "test_flow", run_interval: 60, last_run_status: nil)
      expect(flow).to be_valid
    end

    it "allows success last_run_status" do
      flow = described_class.new(name: "test_flow", run_interval: 60, last_run_status: "success")
      expect(flow).to be_valid
    end

    it "allows failed last_run_status" do
      flow = described_class.new(name: "test_flow", run_interval: 60, last_run_status: "failed")
      expect(flow).to be_valid
    end
  end

  describe "associations" do
    it "has many data_flow_runs" do
      association = described_class.reflect_on_association(:data_flow_runs)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe "scopes" do
    describe ".enabled" do
      it "returns only enabled flows" do
        enabled_flow = described_class.create!(name: "enabled", run_interval: 60, enabled: true)
        disabled_flow = described_class.create!(name: "disabled", run_interval: 60, enabled: false)

        expect(described_class.enabled).to include(enabled_flow)
        expect(described_class.enabled).not_to include(disabled_flow)
      end
    end

    describe ".due_to_run" do
      it "returns flows with null last_run_at" do
        flow = described_class.create!(name: "never_run", run_interval: 60, last_run_at: nil)
        expect(described_class.due_to_run).to include(flow)
      end

      it "returns flows where interval has elapsed" do
        flow = described_class.create!(
          name: "due_flow",
          run_interval: 60,
          last_run_at: 2.minutes.ago
        )
        expect(described_class.due_to_run).to include(flow)
      end

      it "does not return flows where interval has not elapsed" do
        flow = described_class.create!(
          name: "not_due",
          run_interval: 3600,
          last_run_at: 30.minutes.ago
        )
        expect(described_class.due_to_run).not_to include(flow)
      end

      it "does not return disabled flows" do
        flow = described_class.create!(
          name: "disabled_due",
          run_interval: 60,
          last_run_at: 2.minutes.ago,
          enabled: false
        )
        expect(described_class.due_to_run).not_to include(flow)
      end
    end
  end

  describe "#flow_class" do
    it "constantizes class name from configuration hash" do
      flow = described_class.new(
        name: "test",
        run_interval: 60,
        configuration: { "class_name" => "String" }
      )
      expect(flow.flow_class).to eq(String)
    end

    it "constantizes class name from configuration string" do
      flow = described_class.new(
        name: "test",
        run_interval: 60,
        configuration: "String"
      )
      expect(flow.flow_class).to eq(String)
    end
  end

  describe "#trigger_run!" do
    it "delegates to FlowExecutor" do
      flow = described_class.create!(name: "test", run_interval: 60)
      expect(ActiveDataFlow::RailsHeartbeatApp::FlowExecutor).to receive(:execute).with(flow)
      flow.trigger_run!
    end
  end
end
