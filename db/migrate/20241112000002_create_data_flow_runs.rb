# frozen_string_literal: true

class CreateDataFlowRuns < ActiveRecord::Migration[6.0]
  def change
    create_table :data_flow_runs do |t|
      t.references :data_flow, null: false, foreign_key: true
      t.string :status, null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.text :error_message
      t.text :error_backtrace

      t.timestamps
    end

    add_index :data_flow_runs, [:data_flow_id, :created_at]
  end
end
