class ProductService
  def self.list_all
    DB[:products].all
  end

  def self.find_by_id(id)
    DB[:products][id: id.to_i]
  end

  def self.update(id, params)
    product = DB[:products][id: id.to_i]
    return nil unless product

    # Actualización de campos sin stock
    updated_values = {
      name: params['name'] || product[:name],
      description: params['description'] || product[:description],
      price: params['price'] || product[:price],
      stock: params['stock'] || product[:stock] # Solo cambia stock si se pasa explícitamente
    }

    DB[:products].where(id: id.to_i).update(updated_values)
    true
  end

  def self.reduce_stock(id, quantity)
    product = DB[:products][id: id.to_i]
    return nil unless product

    new_stock = product[:stock] - quantity
    raise StandardError, 'El stock no puede ser negativo' if new_stock < 0

    DB[:products].where(id: id.to_i).update(stock: new_stock)
    true
  end

  def self.delete(id)
    product = DB[:products][id: id.to_i]
    return nil unless product

    DB[:products].where(id: id.to_i).delete
    true
  end
end
