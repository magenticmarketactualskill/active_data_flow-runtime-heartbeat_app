# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :data_flows, force: :cascade do |t|
    t.string :name, null: false
    t.text :description
    t.boolean :enabled, default: true, null: false
    t.text :configuration
    t.integer :run_interval, null: false
    t.datetime :last_run_at
    t.string :last_run_status
    t.timestamps
  end

  add_index :data_flows, :name, unique: true
  add_index :data_flows, [:enabled, :last_run_at]

  create_table :data_flow_runs, force: :cascade do |t|
    t.integer :data_flow_id, null: false
    t.string :status, null: false
    t.datetime :started_at, null: false
    t.datetime :ended_at
    t.text :error_message
    t.text :error_backtrace
    t.timestamps
  end

  add_index :data_flow_runs, :data_flow_id
  add_index :data_flow_runs, [:data_flow_id, :created_at]
end
