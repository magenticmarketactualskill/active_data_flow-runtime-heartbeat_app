# frozen_string_literal: true

class CreateDataFlows < ActiveRecord::Migration[6.0]
  def change
    create_table :data_flows do |t|
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
  end
end
