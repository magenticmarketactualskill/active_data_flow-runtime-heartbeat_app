# ActiveDataFlow Rails Heartbeat App - Requirements Document

## Introduction

This document specifies the requirements for the Rails Heartbeat App, a runtime component that enables periodic execution of DataFlows within a Rails application process. The system responds to HTTP heartbeat requests by identifying and executing DataFlows that are due to run based on their configured intervals.

## Glossary

- **Rails Heartbeat App**: The system being specified; a Rails engine that manages DataFlow execution
- **DataFlow**: A configurable workflow unit that performs data processing operations
- **Heartbeat Request**: An HTTP request sent to trigger the execution cycle
- **Flow Record**: A database entry containing DataFlow configuration and execution state
- **Run Record**: A database entry logging a single DataFlow execution attempt
- **Due Flow**: A Flow Record where the time since last execution exceeds the configured interval
- **Execution Cycle**: The process of identifying and running all Due Flows
- **Authentication Token**: A secret string used to validate heartbeat requests
- **Whitelisted IP**: An IP address authorized to send heartbeat requests

## Requirements

### Requirement 1: Flow Record Persistence

**User Story:** As a system administrator, I want DataFlow configurations stored in the database, so that I can manage flows without code deployments.

#### Acceptance Criteria

1.1 THE Rails Heartbeat App SHALL persist Flow Records with name, description, enabled flag, and configuration data

1.2 THE Rails Heartbeat App SHALL persist Flow Records with run interval measured in seconds, last execution timestamp, and last execution status

1.3 THE Rails Heartbeat App SHALL enforce unique names across all Flow Records

1.4 THE Rails Heartbeat App SHALL enforce run intervals greater than zero seconds

### Requirement 2: Run Record Logging

**User Story:** As a system administrator, I want execution history logged, so that I can audit DataFlow behavior and diagnose failures.

#### Acceptance Criteria

2.1 THE Rails Heartbeat App SHALL create a Run Record for each DataFlow execution attempt

2.2 THE Rails Heartbeat App SHALL record the start timestamp, end timestamp, and status in each Run Record

2.3 THE Rails Heartbeat App SHALL record error messages and stack traces in Run Records WHERE execution fails

2.4 THE Rails Heartbeat App SHALL associate each Run Record with its parent Flow Record

2.5 THE Rails Heartbeat App SHALL restrict Run Record status values to: pending, in_progress, success, or failed

### Requirement 3: Due Flow Identification

**User Story:** As a system operator, I want the system to identify flows ready for execution, so that flows run at their configured intervals.

#### Acceptance Criteria

3.1 WHEN a Heartbeat Request is received, THE Rails Heartbeat App SHALL identify all enabled Flow Records as candidates

3.2 WHEN evaluating a candidate Flow Record, THE Rails Heartbeat App SHALL classify it as a Due Flow IF the current time minus last execution timestamp exceeds the run interval

3.3 WHEN evaluating a candidate Flow Record with no last execution timestamp, THE Rails Heartbeat App SHALL classify it as a Due Flow

3.4 THE Rails Heartbeat App SHALL acquire a database lock on each Due Flow to prevent concurrent execution

3.5 IF a database lock cannot be acquired on a Due Flow, THEN THE Rails Heartbeat App SHALL skip that flow and continue processing other flows

### Requirement 4: DataFlow Execution

**User Story:** As a developer, I want DataFlows executed synchronously in the application process, so that lightweight flows complete without external job infrastructure.

#### Acceptance Criteria

4.1 WHEN executing a Due Flow, THE Rails Heartbeat App SHALL instantiate the DataFlow class specified in the Flow Record configuration

4.2 WHEN executing a Due Flow, THE Rails Heartbeat App SHALL invoke the run method on the DataFlow instance

4.3 WHEN a DataFlow execution completes without raising an exception, THE Rails Heartbeat App SHALL update the Flow Record status to success

4.4 IF a DataFlow execution raises an exception, THEN THE Rails Heartbeat App SHALL update the Flow Record status to failed

4.5 WHEN a DataFlow execution completes or fails, THE Rails Heartbeat App SHALL update the Flow Record last execution timestamp to the current time

4.6 WHEN a DataFlow execution completes or fails, THE Rails Heartbeat App SHALL finalize the associated Run Record with end timestamp and status

### Requirement 5: Heartbeat Endpoint

**User Story:** As a system operator, I want an HTTP endpoint to trigger execution cycles, so that I can schedule DataFlow execution using external monitoring tools.

#### Acceptance Criteria

5.1 THE Rails Heartbeat App SHALL expose an HTTP endpoint that accepts POST requests

5.2 WHEN the heartbeat endpoint receives a valid request, THE Rails Heartbeat App SHALL initiate an Execution Cycle

5.3 WHEN the Execution Cycle completes, THE Rails Heartbeat App SHALL return a JSON response containing the count of Due Flows identified and the count of flows successfully triggered

5.4 THE Rails Heartbeat App SHALL return HTTP status 200 for successful Execution Cycles

5.5 IF an error occurs during the Execution Cycle, THEN THE Rails Heartbeat App SHALL return HTTP status 500 with error details

### Requirement 6: Authentication

**User Story:** As a security administrator, I want heartbeat requests authenticated, so that unauthorized parties cannot trigger DataFlow execution.

#### Acceptance Criteria

6.1 WHERE authentication is enabled, THE Rails Heartbeat App SHALL require an Authentication Token in the request header

6.2 WHERE authentication is enabled, IF a Heartbeat Request lacks a valid Authentication Token, THEN THE Rails Heartbeat App SHALL return HTTP status 401 and SHALL NOT initiate an Execution Cycle

6.3 THE Rails Heartbeat App SHALL log all authentication failures with timestamp and source IP address

6.4 WHERE authentication is disabled, THE Rails Heartbeat App SHALL process all Heartbeat Requests without token validation

### Requirement 7: IP Whitelisting

**User Story:** As a security administrator, I want IP-based access control, so that only trusted sources can trigger DataFlow execution.

#### Acceptance Criteria

7.1 WHERE IP whitelisting is enabled, THE Rails Heartbeat App SHALL validate the source IP address against the configured whitelist

7.2 WHERE IP whitelisting is enabled, IF a Heartbeat Request originates from a non-Whitelisted IP, THEN THE Rails Heartbeat App SHALL return HTTP status 403 and SHALL NOT initiate an Execution Cycle

7.3 THE Rails Heartbeat App SHALL log all IP whitelist rejections with timestamp and source IP address

7.4 WHERE IP whitelisting is disabled, THE Rails Heartbeat App SHALL process Heartbeat Requests from any source IP

### Requirement 8: Configuration Management

**User Story:** As a developer, I want configurable system behavior, so that I can adapt the Rails Heartbeat App to different deployment environments.

#### Acceptance Criteria

8.1 THE Rails Heartbeat App SHALL accept configuration through a Rails initializer file

8.2 THE Rails Heartbeat App SHALL support configuration of the Authentication Token value

8.3 THE Rails Heartbeat App SHALL support configuration of the Whitelisted IP list

8.4 THE Rails Heartbeat App SHALL support configuration of the heartbeat endpoint URL path

8.5 THE Rails Heartbeat App SHALL support configuration to enable or disable authentication

8.6 THE Rails Heartbeat App SHALL support configuration to enable or disable IP whitelisting

8.7 THE Rails Heartbeat App SHALL use default values for all configuration options when not explicitly set: authentication disabled, IP whitelisting disabled, endpoint path "/data_flows/heartbeat"
