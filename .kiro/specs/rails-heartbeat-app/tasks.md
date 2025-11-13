# Implementation Plan

- [x] 1. Set up Rails Engine structure and dependencies
  - Create gem directory structure with lib, app, config, and db directories
  - Create gemspec file with dependencies on active_data_flow and rails
  - Create engine.rb file that defines the Rails::Engine class
  - Create main module file that loads engine and configuration
  - _Requirements: 8.1_

- [x] 2. Implement configuration system
  - [x] 2.1 Create Configuration class with default values
    - Write Configuration class with attr_accessors for all config options
    - Set default values: authentication_enabled=false, ip_whitelisting_enabled=false, endpoint_path='/data_flows/heartbeat'
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_
  
  - [x] 2.2 Add module-level configuration methods
    - Implement config class method that returns singleton Configuration instance
    - Implement configure class method that yields config to block
    - _Requirements: 8.1_

- [x] 3. Create database migrations
  - [x] 3.1 Create data_flows table migration
    - Write migration with columns: name (string, unique), description (text), enabled (boolean, default true)
    - Add columns: configuration (text), run_interval (integer), last_run_at (datetime), last_run_status (string)
    - Add timestamps
    - Create unique index on name
    - Create composite index on (enabled, last_run_at)
    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  
  - [x] 3.2 Create data_flow_runs table migration
    - Write migration with columns: data_flow_id (references), status (string), started_at (datetime)
    - Add columns: ended_at (datetime), error_message (text), error_backtrace (text)
    - Add timestamps
    - Add foreign key constraint to data_flows
    - Create index on data_flow_id
    - Create composite index on (data_flow_id, created_at)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 4. Implement ActiveRecord models
  - [x] 4.1 Create DataFlow model
    - Write DataFlow class inheriting from ApplicationRecord
    - Add has_many association to data_flow_runs with dependent: :destroy
    - Add validations: name presence and uniqueness, run_interval numericality > 0
    - Add validation: last_run_status inclusion in ['success', 'failed'] with allow_nil
    - Serialize configuration column as JSON
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.4_
  
  - [x] 4.2 Add DataFlow scopes and query methods
    - Implement enabled scope filtering where enabled=true
    - Implement due_to_run scope that finds flows where last_run_at is null or exceeds interval
    - _Requirements: 3.1, 3.2, 3.3_
  
  - [x] 4.3 Add DataFlow instance methods
    - Implement flow_class method that constantizes class name from configuration
    - Implement trigger_run! method that delegates to FlowExecutor
    - _Requirements: 4.1, 4.2_
  
  - [x] 4.4 Create DataFlowRun model
    - Write DataFlowRun class inheriting from ApplicationRecord
    - Add belongs_to association to data_flow
    - Add validations: status inclusion in ['pending', 'in_progress', 'success', 'failed']
    - Add validation: started_at presence
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
  
  - [x] 4.5 Add DataFlowRun instance methods
    - Implement duration method that calculates ended_at - started_at
    - Implement success? predicate method
    - Implement failed? predicate method
    - _Requirements: 2.2_

- [x] 5. Implement FlowExecutor service
  - [x] 5.1 Create FlowExecutor class structure
    - Write FlowExecutor class with class method execute(data_flow)
    - Implement initialize method that accepts data_flow parameter
    - Implement execute instance method with error handling
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_
  
  - [x] 5.2 Implement run record lifecycle management
    - Implement create_run_record method that creates pending run, then updates to in_progress
    - Implement mark_success method that updates flow last_run_at and status, and run status and ended_at
    - Implement mark_failure method that updates flow and run with error details
    - _Requirements: 2.1, 2.2, 2.3, 4.3, 4.4, 4.5, 4.6_
  
  - [x] 5.3 Implement DataFlow instantiation and execution
    - Implement instantiate_and_run_flow method that gets flow_class from data_flow
    - Instantiate flow class with configuration from data_flow
    - Call run method on flow instance
    - _Requirements: 4.1, 4.2_

- [x] 6. Implement DataFlowsController
  - [x] 6.1 Create controller class and authentication
    - Write DataFlowsController inheriting from ApplicationController
    - Add skip_before_action for CSRF token verification
    - Implement authenticate_heartbeat! before_action with token validation using secure_compare
    - Implement check_ip_whitelist! before_action with IP validation
    - _Requirements: 5.1, 6.1, 6.2, 6.3, 6.4, 7.1, 7.2, 7.3, 7.4_
  
  - [x] 6.2 Implement heartbeat action
    - Query DataFlow.due_to_run with database lock (FOR UPDATE SKIP LOCKED)
    - Iterate through flows and call FlowExecutor.execute for each
    - Track count of triggered flows, continue on individual flow errors
    - Return JSON response with flows_due, flows_triggered, and timestamp
    - Handle exceptions with 500 status and error message
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 5.2, 5.3, 5.4, 5.5_
  
  - [x] 6.3 Implement security logging
    - Implement log_authentication_failure method that logs timestamp and source IP
    - Implement log_ip_rejection method that logs rejected IP and timestamp
    - _Requirements: 6.3, 7.3_

- [x] 7. Configure routing
  - Create routes.rb in engine config directory
  - Define POST route to data_flows#heartbeat using configured endpoint_path
  - Add named route helper :heartbeat
  - _Requirements: 5.1, 8.4_

- [x] 8. Create engine initialization
  - Write engine.rb that defines Rails::Engine subclass
  - Configure engine to isolate namespace
  - Set up autoload paths for app directory
  - Add initializer to load configuration
  - _Requirements: 8.1_

- [x] 9. Add installation generator
  - Create generator class that copies migrations to host application
  - Add generator template for initializer file with configuration example
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_

- [x] 10. Write model tests
  - [x] 10.1 Write DataFlow model tests
    - Test name presence and uniqueness validations
    - Test run_interval numericality validation
    - Test last_run_status inclusion validation
    - Test enabled scope returns only enabled flows
    - Test due_to_run scope with various last_run_at and run_interval combinations
    - Test flow_class constantization
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 3.1, 3.2, 3.3_
  
  - [x] 10.2 Write DataFlowRun model tests
    - Test belongs_to association to data_flow
    - Test status inclusion validation
    - Test started_at presence validation
    - Test duration calculation with and without ended_at
    - Test success? and failed? predicate methods
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 11. Write service tests
  - [x] 11.1 Write FlowExecutor success path tests
    - Test creates run record with pending then in_progress status
    - Test instantiates flow class with configuration
    - Test calls run method on flow instance
    - Test updates data_flow with success status and last_run_at
    - Test updates run record with success status and ended_at
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_
  
  - [x] 11.2 Write FlowExecutor failure path tests
    - Test captures exception when flow.run raises error
    - Test updates data_flow with failed status
    - Test updates run record with failed status, error_message, and error_backtrace
    - Test re-raises exception after recording failure
    - _Requirements: 4.4, 4.5, 4.6_

- [x] 12. Write controller tests
  - [x] 12.1 Write authentication tests
    - Test returns 401 when authentication enabled and token missing
    - Test returns 401 when authentication enabled and token invalid
    - Test processes request when authentication enabled and token valid
    - Test processes request when authentication disabled
    - Test logs authentication failures
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  
  - [x] 12.2 Write IP whitelist tests
    - Test returns 403 when IP whitelisting enabled and IP not in whitelist
    - Test processes request when IP whitelisting enabled and IP in whitelist
    - Test processes request when IP whitelisting disabled
    - Test logs IP rejections
    - _Requirements: 7.1, 7.2, 7.3, 7.4_
  
  - [x] 12.3 Write heartbeat action tests
    - Test queries due_to_run flows with database lock
    - Test executes each due flow via FlowExecutor
    - Test returns JSON with flows_due and flows_triggered counts
    - Test returns 200 status on success
    - Test continues execution when individual flow fails
    - Test returns 500 status when exception occurs
    - _Requirements: 3.4, 3.5, 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 13. Write integration tests
  - Test end-to-end flow: create flow record, trigger heartbeat, verify execution and run record
  - Test multiple flows with different intervals execute correctly
  - Test failed flow doesn't block execution of other flows
  - Test concurrent heartbeat requests don't duplicate execution (database locking)
  - _Requirements: 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_
