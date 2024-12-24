require 'sequel'

DB = Sequel.connect('postgres://postgres:postgres@localhost/wompi_test')

Sequel.extension :migration
Sequel::Migrator.run(DB, 'db/migrations')

puts 'Migraciones completadas correctamente.'
