require_relative '../config/database'

# Insertar productos iniciales
DB[:products].insert(
  name: 'Producto A',
  description: 'Descripción del Producto A',
  price: 10000,
  stock: 10
)

DB[:products].insert(
  name: 'Producto B',
  description: 'Descripción del Producto B',
  price: 15000,
  stock: 5
)

puts 'Datos iniciales insertados correctamente.'
