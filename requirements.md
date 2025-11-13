# ActiveDataFlow Rails Heartbeat App - Requirements Document

## Introduction

This document specifies the requirements for the `active_data_flow-rails_heartbeat_app` gem, which provides a heartbeat-triggered execution model for DataFlows running in the Rails application process.

**Dependencies:**
- `active_data_flow` (core) - Provides DataFlow module and base classes

This runtime gem extends the core `active_data_flow` gem with synchronous execution capabilities in the Rails application process, triggered by periodic heartbeat HTTP requests.

## Glossary

- **Heartbeat**: A periodic HTTP request that triggers DataFlow execution
- **DataFlow Record**: A database record storing flow configuration and state
- **DataFlowRun**: A database record logging individual execution history

## Requirements

### Requirement 1: Database Schema

**User Story:** As a system operator, I want database tables for flow configuration, so that I can manage DataFlows through the database.

#### Acceptance Criteria

1. THE RailsHeartbeatApp SHALL provide a migration for the data_flows table
2. THE data_flows table SHALL include name, description, enabled, configuration columns
3. THE data_flows table SHALL include run_interval, last_run_at, last_run_status columns
4. THE RailsHeartbeatApp SHALL provide a migration for the data_flow_runs table
5. THE data_flow_runs table SHALL include status, started_at, ended_at, error columns

### Requirement 2: DataFlow Model

**User Story:** As a developer, I want an ActiveRecord model for DataFlows, so that I can query and manage flows programmatically.

#### Acceptance Criteria

1. THE RailsHeartbeatApp SHALL provide a DataFlow ActiveRecord model
2. THE DataFlow model SHALL validate name presence and uniqueness
3. THE DataFlow model SHALL validate run_interval is a positive integer
4. THE DataFlow model SHALL provide a `due_to_run` scope for querying ready flows
5. THE DataFlow model SHALL provide a `trigger_run!` method to start execution

### Requirement 3: DataFlowRun Model

**User Story:** As a system operator, I want execution history logging, so that I can audit and debug DataFlow runs.

#### Acceptance Criteria

1. THE RailsHeartbeatApp SHALL provide a DataFlowRun ActiveRecord model
2. THE DataFlowRun SHALL belong to a DataFlow
3. THE DataFlowRun SHALL validate status is one of: pending, in_progress, success, failed
4. THE DataFlowRun SHALL provide a `duration` method calculating execution time
5. THE DataFlowRun SHALL store error messages and backtraces for failures

### Requirement 4: Heartbeat Controller

**User Story:** As a system operator, I want a heartbeat endpoint, so that I can trigger DataFlow execution via HTTP.

#### Acceptance Criteria

1. THE RailsHeartbeatApp SHALL provide a DataFlowsController with heartbeat action
2. THE heartbeat action SHALL query for due DataFlows using the due_to_run scope
3. THE heartbeat action SHALL use database locking (FOR UPDATE SKIP LOCKED) to prevent races
4. THE heartbeat action SHALL call trigger_run! on each due flow
5. THE heartbeat action SHALL return JSON with flows_due and flows_triggered counts

### Requirement 5: Synchronous Execution

**User Story:** As a developer, I want synchronous execution in the app process, so that I can run lightweight flows without background jobs.

#### Acceptance Criteria

1. THE RailsHeartbeatApp SHALL execute DataFlows synchronously in the heartbeat request
2. WHEN trigger_run! is called, THE RailsHeartbeatApp SHALL instantiate the DataFlow class
3. THE RailsHeartbeatApp SHALL call the run method on the DataFlow instance
4. THE RailsHeartbeatApp SHALL update last_run_status to success or failed
5. THE RailsHeartbeatApp SHALL create DataFlowRun records with execution details

### Requirement 6: Security

**User Story:** As a system operator, I want secure heartbeat endpoints, so that unauthorized users cannot trigger executions.

#### Acceptance Criteria

1. THE RailsHeartbeatApp SHALL support authentication token validation
2. THE RailsHeartbeatApp SHALL support IP whitelisting configuration
3. THE RailsHeartbeatApp SHALL log all heartbeat requests with timestamps
4. THE RailsHeartbeatApp SHALL return 401 Unauthorized for invalid authentication
5. THE RailsHeartbeatApp SHALL return 403 Forbidden for non-whitelisted IPs

### Requirement 7: Configuration

**User Story:** As a developer, I want configurable heartbeat settings, so that I can customize the execution behavior.

#### Acceptance Criteria

1. THE RailsHeartbeatApp SHALL support configuration via Rails initializer
2. THE RailsHeartbeatApp SHALL allow configuring authentication token
3. THE RailsHeartbeatApp SHALL allow configuring IP whitelist
4. THE RailsHeartbeatApp SHALL allow configuring heartbeat endpoint path
5. THE RailsHeartbeatApp SHALL provide sensible defaults for all settings
