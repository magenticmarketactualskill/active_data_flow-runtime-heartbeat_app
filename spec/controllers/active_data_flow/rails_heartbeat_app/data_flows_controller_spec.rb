# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveDataFlow::RailsHeartbeatApp::DataFlowsController, type: :controller do
  routes { ActiveDataFlow::RailsHeartbeatApp::Engine.routes }

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

  before do
    stub_const("MockFlow", mock_flow_class)
  end

  describe "POST #heartbeat" do
    context "authentication" do
      context "when authentication is enabled" do
        before do
          ActiveDataFlow::RailsHeartbeatApp.config.authentication_enabled = true
          ActiveDataFlow::RailsHeartbeatApp.config.authentication_token = "secret_token"
        end

        after do
          ActiveDataFlow::RailsHeartbeatApp.config.authentication_enabled = false
          ActiveDataFlow::RailsHeartbeatApp.config.authentication_token = nil
        end

        it "returns 401 when token is missing" do
          post :heartbeat
          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)["error"]).to eq("Unauthorized")
        end

        it "returns 401 when token is invalid" do
          request.headers["X-Heartbeat-Token"] = "wrong_token"
          post :heartbeat
          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)["error"]).to eq("Unauthorized")
        end

        it "processes request when token is valid" do
          request.headers["X-Heartbeat-Token"] = "secret_token"
          post :heartbeat
          expect(response).to have_http_status(:ok)
        end

        it "logs authentication failures" do
          allow(Rails.logger).to receive(:warn)
          post :heartbeat
          expect(Rails.logger).to have_received(:warn).with(/Heartbeat authentication failed/)
        end
      end

      context "when authentication is disabled" do
        before do
          ActiveDataFlow::RailsHeartbeatApp.config.authentication_enabled = false
        end

        it "processes request without token" do
          post :heartbeat
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "IP whitelisting" do
      context "when IP whitelisting is enabled" do
        before do
          ActiveDataFlow::RailsHeartbeatApp.config.ip_whitelisting_enabled = true
          ActiveDataFlow::RailsHeartbeatApp.config.whitelisted_ips = ["127.0.0.1", "192.168.1.100"]
        end

        after do
          ActiveDataFlow::RailsHeartbeatApp.config.ip_whitelisting_enabled = false
          ActiveDataFlow::RailsHeartbeatApp.config.whitelisted_ips = []
        end

        it "returns 403 when IP is not in whitelist" do
          allow(controller.request).to receive(:remote_ip).and_return("10.0.0.1")
          post :heartbeat
          expect(response).to have_http_status(:forbidden)
          expect(JSON.parse(response.body)["error"]).to eq("Forbidden")
        end

        it "processes request when IP is in whitelist" do
          allow(controller.request).to receive(:remote_ip).and_return("127.0.0.1")
          post :heartbeat
          expect(response).to have_http_status(:ok)
        end

        it "logs IP rejections" do
          allow(Rails.logger).to receive(:warn)
          allow(controller.request).to receive(:remote_ip).and_return("10.0.0.1")
          post :heartbeat
          expect(Rails.logger).to have_received(:warn).with(/Heartbeat IP whitelist rejection/)
        end
      end

      context "when IP whitelisting is disabled" do
        before do
          ActiveDataFlow::RailsHeartbeatApp.config.ip_whitelisting_enabled = false
        end

        it "processes request from any IP" do
          allow(controller.request).to receive(:remote_ip).and_return("10.0.0.1")
          post :heartbeat
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "heartbeat action" do
      let!(:due_flow) do
        ActiveDataFlow::RailsHeartbeatApp::DataFlow.create!(
          name: "due_flow",
          run_interval: 60,
          last_run_at: 2.minutes.ago,
          configuration: { "class_name" => "MockFlow" }
        )
      end

      let!(:not_due_flow) do
        ActiveDataFlow::RailsHeartbeatApp::DataFlow.create!(
          name: "not_due_flow",
          run_interval: 3600,
          last_run_at: 30.minutes.ago,
          configuration: { "class_name" => "MockFlow" }
        )
      end

      it "queries due_to_run flows" do
        post :heartbeat
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["flows_due"]).to eq(1)
      end

      it "executes each due flow via FlowExecutor" do
        expect(ActiveDataFlow::RailsHeartbeatApp::FlowExecutor).to receive(:execute).with(due_flow)
        post :heartbeat
      end

      it "returns JSON with flows_due and flows_triggered counts" do
        post :heartbeat
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body).to have_key("flows_due")
        expect(body).to have_key("flows_triggered")
        expect(body).to have_key("timestamp")
      end

      it "returns 200 status on success" do
        post :heartbeat
        expect(response).to have_http_status(:ok)
      end

      it "continues execution when individual flow fails" do
        failing_flow = ActiveDataFlow::RailsHeartbeatApp::DataFlow.create!(
          name: "failing_flow",
          run_interval: 60,
          last_run_at: 2.minutes.ago,
          configuration: { "class_name" => "MockFlow" }
        )

        allow(ActiveDataFlow::RailsHeartbeatApp::FlowExecutor).to receive(:execute).with(due_flow)
        allow(ActiveDataFlow::RailsHeartbeatApp::FlowExecutor).to receive(:execute).with(failing_flow).and_raise(StandardError, "Flow failed")
        allow(Rails.logger).to receive(:error)

        post :heartbeat
        expect(response).to have_http_status(:ok)
        expect(Rails.logger).to have_received(:error).with(/Flow execution failed/)
      end

      it "returns 500 status when exception occurs" do
        allow(ActiveDataFlow::RailsHeartbeatApp::DataFlow).to receive(:due_to_run).and_raise(StandardError, "Database error")

        post :heartbeat
        expect(response).to have_http_status(:internal_server_error)
        body = JSON.parse(response.body)
        expect(body["error"]).to eq("Database error")
      end
    end
  end
end
