Sequel.migration do
  change do
    create_table(:transactions) do
      primary_key :id
      foreign_key :product_id, :products
      String :status, null: false, default: 'PENDING'
      String :transaction_id
      Float :amount, null: false
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
