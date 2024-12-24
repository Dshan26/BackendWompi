require 'sequel'

DB = Sequel.connect(
  adapter: 'postgres',
  user: 'postgres',
  password: 'postgres',
  host: 'localhost',
  database: 'wompi_test'
)
