Sequel.migration do
  change do
    create_table(:customers) do
      primary_key :id
      String :name, null: false
      String :email, null: false, unique: true
      String :phone
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
