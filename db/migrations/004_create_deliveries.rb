Sequel.migration do
  change do
    create_table(:deliveries) do
      primary_key :id
      foreign_key :transaction_id, :transactions
      String :address, null: false
      String :status, null: false, default: 'PENDING'
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
