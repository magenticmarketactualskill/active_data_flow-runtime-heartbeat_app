# Quick Start Guide

## Installation

```bash
# Add to Gemfile
gem 'active_data_flow-rails_heartbeat_app'

# Install
bundle install

# Generate migrations and initializer
rails generate active_data_flow:rails_heartbeat_app:install

# Run migrations
rails db:migrate
```

## Configuration

Edit `config/initializers/active_data_flow_rails_heartbeat_app.rb`:

```ruby
ActiveDataFlow::RailsHeartbeatApp.configure do |config|
  config.authentication_enabled = true
  config.authentication_token = ENV["HEARTBEAT_TOKEN"]
end
```

## Create a DataFlow

```ruby
# app/flows/my_app/flows/data_sync_flow.rb
module MyApp
  module Flows
    class DataSyncFlow
      include ActiveDataFlow::DataFlow

      def run
        # Your flow logic here
        logger.info "Syncing data..."
        # ... perform sync ...
        logger.info "Sync complete!"
      end
    end
  end
end
```

## Register the Flow

```ruby
# In Rails console or seed file
ActiveDataFlow::RailsHeartbeatApp::DataFlow.create!(
  name: "data_sync",
  description: "Syncs data every 5 minutes",
  run_interval: 300, # 5 minutes in seconds
  enabled: true,
  configuration: {
    class_name: "MyApp::Flows::DataSyncFlow"
  }
)
```

## Trigger Execution

### Manual Test
```bash
curl -X POST \
  -H "X-Heartbeat-Token: your_token" \
  http://localhost:3000/data_flows/heartbeat
```

### Cron Job
```bash
# Add to crontab
*/5 * * * * curl -X POST -H "X-Heartbeat-Token: $TOKEN" https://your-app.com/data_flows/heartbeat
```

### Kubernetes CronJob
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: dataflow-heartbeat
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: heartbeat
            image: curlimages/curl:latest
            env:
            - name: TOKEN
              valueFrom:
                secretKeyRef:
                  name: heartbeat-secret
                  key: token
            command:
            - /bin/sh
            - -c
            - curl -X POST -H "X-Heartbeat-Token: $TOKEN" https://your-app.com/data_flows/heartbeat
          restartPolicy: OnFailure
```

## Monitor Execution

```ruby
# View recent runs
flow = ActiveDataFlow::RailsHeartbeatApp::DataFlow.find_by(name: "data_sync")
flow.data_flow_runs.order(created_at: :desc).limit(10).each do |run|
  puts "#{run.started_at}: #{run.status} (#{run.duration}s)"
  if run.failed?
    puts "Error: #{run.error_message}"
  end
end

# Check flow status
flow.last_run_status # => "success" or "failed"
flow.last_run_at     # => timestamp of last execution
```

## Troubleshooting

### Flow not executing?
1. Check if flow is enabled: `flow.enabled?`
2. Check if flow is due: `ActiveDataFlow::RailsHeartbeatApp::DataFlow.due_to_run.include?(flow)`
3. Check authentication token is correct
4. Check IP is whitelisted (if enabled)

### Flow failing?
1. Check error message: `flow.data_flow_runs.last.error_message`
2. Check backtrace: `flow.data_flow_runs.last.error_backtrace`
3. Test flow manually: `flow.trigger_run!`

### Authentication issues?
1. Verify token in initializer matches request header
2. Check logs for authentication failures
3. Temporarily disable authentication for testing

## Best Practices

1. **Use environment variables** for sensitive configuration
2. **Monitor execution history** regularly
3. **Set appropriate run_interval** based on flow complexity
4. **Keep flows lightweight** (< 5 seconds execution time)
5. **Use background jobs** for long-running operations
6. **Enable authentication** in production
7. **Whitelist IPs** for additional security
8. **Log important events** in your flow logic
9. **Handle errors gracefully** in your flows
10. **Test flows** before enabling in production
