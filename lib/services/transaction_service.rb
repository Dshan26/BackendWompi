require 'securerandom'
require_relative '../../config/wompi'
require_relative 'payment_service'


class TransactionService
  # Crear una nueva transacción
  def self.create_transaction(payload)
    product = DB[:products][id: payload['product_id']]
    return { error: 'Producto no encontrado' } unless product
  
    # Obtener el acceptance_token
    acceptance_token = PaymentService.get_acceptance_token
    raise "Error al obtener el acceptance_token" if acceptance_token.nil?
  
    # Generar la firma
    reference = payload['reference'] || SecureRandom.uuid
    amount_in_cents = (product[:price] * 100).to_i
    integrity_secret = WOMPI_CONFIG[:integrity_secret]
    expiration_time = payload['expiration_time'] # Opcional
  
    signature = PaymentService.generate_signature(
      reference,
      amount_in_cents,
      'COP',
      integrity_secret,
      expiration_time
    )
  
    # Crear transacción en Wompi
    wompi_payload = {
      acceptance_token: acceptance_token,
      amount_in_cents: amount_in_cents,
      currency: 'COP',
      customer_email: payload['customer_email'],
      payment_method: payload['payment_method'],
      reference: reference,
      expiration_time: expiration_time,
      signature: signature
    }
  
    uri = URI("#{WOMPI_CONFIG[:sandbox_url]}/transactions")
    response = PaymentService.send_post_request(uri, wompi_payload)
    result = JSON.parse(response.body)
  
    if result['error']
      return { error: "Error al crear la transacción en Wompi: #{result['error']['reason']}" }
    end
  
    transaction_id = result.dig('data', 'id')
  
    # Registrar en la base de datos local
    DB[:transactions].insert(
      product_id: product[:id],
      transaction_id: transaction_id,
      amount: amount_in_cents,
      status: 'PENDING'
    )
  
    { transaction_id: transaction_id, amount_in_cents: amount_in_cents, reference: reference }
  end
  
  

  # Procesar un pago
  def self.process_payment(payload)
    # Verificar que la transacción exista
    transaction = DB[:transactions][transaction_id: payload['transaction_id']]
    return { error: 'Transacción no encontrada' } unless transaction

    # Construir parámetros para el servicio de pago
    payment_params = {
      amount_in_cents: transaction[:amount].to_i,
      reference: transaction[:transaction_id],
      expiration_time: payload['expiration_time'],
      currency: payload['currency'] || 'COP',
      customer_email: payload['customer_email'],
      payment_method: payload['payment_method'],
      redirect_url: payload['redirect_url'],
      customer_data: payload['customer_data'],
      shipping_address: payload['shipping_address']
    }

    # Llamar al servicio de pago
    response = PaymentService.process_payment(payment_params)
    puts "Respuesta del servicio de pago: #{response}"

    if response['error']
      return { error: "Error al procesar el pago: #{response['error']['messages']}" }
    end

    # Actualizar estado de la transacción
    update_transaction_status(transaction[:transaction_id], response.dig('data', 'status'))

    # Si el pago fue aprobado, actualizar el inventario
    if response.dig('data', 'status') == 'APPROVED'
      update_product_stock(transaction[:product_id])
    end

    response
  end

  # Obtener detalles de una transacción
  def self.get_transaction_details(transaction_id)
    transaction = DB[:transactions][transaction_id: transaction_id]
    return nil unless transaction

    product = DB[:products][id: transaction[:product_id]]
    customer = DB[:customers][id: transaction[:customer_id]]
    delivery = DB[:deliveries][transaction_id: transaction[:id]]

    { transaction: transaction, product: product, customer: customer, delivery: delivery }
  end

  def self.register_delivery(payload)
    # Verificar si la transacción existe
    transaction = DB[:transactions][transaction_id: payload['transaction_id']]
    return { error: 'Transacción no encontrada' } unless transaction
  
    # Insertar en la tabla deliveries y devolver el ID generado
    delivery_id = DB[:deliveries].insert(
      transaction_id: transaction[:id],
      status: payload['status'] || 'PENDING',
      address: payload['address']
    )
  
    { delivery_id: delivery_id }
  end
  

  private

  # Actualizar el estado de una transacción
  def self.update_transaction_status(transaction_id, status)
    DB[:transactions].where(transaction_id: transaction_id).update(status: status)
  end

  # Reducir el stock del producto asociado a una transacción
  def self.update_product_stock(product_id)
    DB[:products].where(id: product_id).update(stock: Sequel[:stock] - 1)
  end

  def self.get_transaction_status(transaction_id)
    # Verificar si la transacción existe localmente
    transaction = DB[:transactions][transaction_id: transaction_id]
    return { error: 'Transacción no encontrada localmente' } unless transaction
  
    begin
      uri = URI("#{WOMPI_CONFIG[:sandbox_url]}/transactions/#{transaction_id}")
      response = Net::HTTP.get_response(uri)
      result = JSON.parse(response.body)
  
      puts "Respuesta de Wompi: #{result}"
  
      if result['error']
        return { error: "Error al consultar el estado: #{result['error']['reason']}" }
      end
  
      status = result.dig('data', 'status')
  
      # Actualizar solo si el estado cambió
      if transaction[:status] != status
        DB[:transactions].where(transaction_id: transaction_id).update(status: status)
      end
  
      { transaction_id: transaction_id, status: status, details: result['data'] }
    rescue => e
      { error: "Error al consultar Wompi: #{e.message}" }
    end
  end
  

end
