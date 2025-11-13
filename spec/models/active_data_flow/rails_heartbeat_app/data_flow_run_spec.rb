# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveDataFlow::RailsHeartbeatApp::DataFlowRun, type: :model do
  let(:data_flow) do
    ActiveDataFlow::RailsHeartbeatApp::DataFlow.create!(
      name: "test_flow",
      run_interval: 60
    )
  end

  describe "associations" do
    it "belongs to data_flow" do
      association = described_class.reflect_on_association(:data_flow)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "validates status inclusion" do
      run = described_class.new(
        data_flow: data_flow,
        status: "invalid",
        started_at: Time.current
      )
      expect(run).not_to be_valid
      expect(run.errors[:status]).to include("is not included in the list")
    end

    it "allows pending status" do
      run = described_class.new(
        data_flow: data_flow,
        status: "pending",
        started_at: Time.current
      )
      expect(run).to be_valid
    end

    it "allows in_progress status" do
      run = described_class.new(
        data_flow: data_flow,
        status: "in_progress",
        started_at: Time.current
      )
      expect(run).to be_valid
    end

    it "allows success status" do
      run = described_class.new(
        data_flow: data_flow,
        status: "success",
        started_at: Time.current
      )
      expect(run).to be_valid
    end

    it "allows failed status" do
      run = described_class.new(
        data_flow: data_flow,
        status: "failed",
        started_at: Time.current
      )
      expect(run).to be_valid
    end

    it "validates presence of started_at" do
      run = described_class.new(
        data_flow: data_flow,
        status: "pending"
      )
      expect(run).not_to be_valid
      expect(run.errors[:started_at]).to include("can't be blank")
    end
  end

  describe "#duration" do
    it "returns nil when ended_at is nil" do
      run = described_class.new(
        data_flow: data_flow,
        status: "in_progress",
        started_at: Time.current
      )
      expect(run.duration).to be_nil
    end

    it "calculates duration when ended_at is present" do
      started = Time.current
      ended = started + 5.seconds
      run = described_class.new(
        data_flow: data_flow,
        status: "success",
        started_at: started,
        ended_at: ended
      )
      expect(run.duration).to be_within(0.1).of(5.0)
    end
  end

  describe "#success?" do
    it "returns true when status is success" do
      run = described_class.new(
        data_flow: data_flow,
        status: "success",
        started_at: Time.current
      )
      expect(run.success?).to be true
    end

    it "returns false when status is not success" do
      run = described_class.new(
        data_flow: data_flow,
        status: "failed",
        started_at: Time.current
      )
      expect(run.success?).to be false
    end
  end

  describe "#failed?" do
    it "returns true when status is failed" do
      run = described_class.new(
        data_flow: data_flow,
        status: "failed",
        started_at: Time.current
      )
      expect(run.failed?).to be true
    end

    it "returns false when status is not failed" do
      run = described_class.new(
        data_flow: data_flow,
        status: "success",
        started_at: Time.current
      )
      expect(run.failed?).to be false
    end
  end
end
