# ActiveDataFlow Rails Heartbeat App

A Rails engine that provides database-backed, HTTP-triggered synchronous execution of ActiveDataFlow DataFlows.

## Features

- **Database-Driven Configuration**: Store DataFlow configurations in the database
- **HTTP Heartbeat Trigger**: Execute flows via periodic HTTP requests
- **Synchronous Execution**: Run lightweight flows in the Rails application process
- **Concurrency Safety**: Database-level locking prevents duplicate execution
- **Audit Trail**: Complete execution history with timestamps and error details
- **Security**: Token-based authentication and IP whitelisting

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_data_flow-rails_heartbeat_app'
```

And then execute:

```bash
$ bundle install
```

Run the installation generator:

```bash
$ rails generate active_data_flow:rails_heartbeat_app:install
$ rails db:migrate
```

## Configuration

Create an initializer at `config/initializers/active_data_flow_rails_heartbeat_app.rb`:

```ruby
ActiveDataFlow::RailsHeartbeatApp.configure do |config|
  # Enable authentication (recommended for production)
  config.authentication_enabled = true
  config.authentication_token = ENV["HEARTBEAT_TOKEN"]

  # Enable IP whitelisting (optional)
  config.ip_whitelisting_enabled = true
  config.whitelisted_ips = ["10.0.0.0/8", "172.16.0.0/12"]

  # Customize endpoint path (optional)
  config.endpoint_path = "/data_flows/heartbeat"
end
```

## Usage

### Creating DataFlows

Create a DataFlow record in the database:

```ruby
ActiveDataFlow::RailsHeartbeatApp::DataFlow.create!(
  name: "data_sync_flow",
  description: "Syncs data every 5 minutes",
  run_interval: 300, # seconds
  enabled: true,
  configuration: {
    class_name: "MyApp::Flows::DataSyncFlow",
    options: {
      batch_size: 100
    }
  }
)
```

### Triggering Execution

Send a POST request to the heartbeat endpoint:

```bash
curl -X POST \
  -H "X-Heartbeat-Token: your_token_here" \
  https://your-app.com/data_flows/heartbeat
```

### Scheduling with Cron

Add to your crontab:

```
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
            args:
            - /bin/sh
            - -c
            - curl -X POST -H "X-Heartbeat-Token: $TOKEN" https://your-app.com/data_flows/heartbeat
          restartPolicy: OnFailure
```

## Monitoring

View execution history:

```ruby
flow = ActiveDataFlow::RailsHeartbeatApp::DataFlow.find_by(name: "data_sync_flow")
flow.data_flow_runs.order(created_at: :desc).limit(10).each do |run|
  puts "#{run.started_at}: #{run.status} (#{run.duration}s)"
  puts run.error_message if run.failed?
end
```

## Development

After checking out the repo, run:

```bash
bundle install
bundle exec rspec
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
