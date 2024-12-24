require 'sinatra'
require 'sinatra/json'
require_relative 'config/database'
require_relative 'lib/services/product_service'
require_relative 'lib/services/transaction_service'
require_relative 'lib/services/payment_service'
require_relative 'lib/services/customer_service'
require 'dotenv'
Dotenv.load

require 'sinatra/cors'

set :allow_origin, "http://localhost:5173"
set :allow_methods, "GET,HEAD,POST,PUT,DELETE,OPTIONS"
set :allow_headers, "Content-Type,Authorization,X-Requested-With,Access-Control-Allow-Origin"
set :expose_headers, "Content-Length"


# Endpoint para listar todos los productos
get '/products' do
  json ProductService.list_all
end

# Endpoint para obtener un producto por ID
get '/products/:id' do
  product = ProductService.find_by_id(params[:id])
  halt 404, json(message: 'Producto no encontrado') unless product
  json product
end

# Endpoint para actualizar un producto
put '/products/:id' do
  request_payload = JSON.parse(request.body.read)
  updated = ProductService.update(params[:id], request_payload)
  halt 404, json(message: 'Producto no encontrado') unless updated
  json message: 'Producto actualizado'
end

# Endpoint para eliminar un producto
delete '/products/:id' do
  deleted = ProductService.delete(params[:id])
  halt 404, json(message: 'Producto no encontrado') unless deleted
  json message: 'Producto eliminado'
end

put '/products/:id/reduce-stock' do
  request_payload = JSON.parse(request.body.read)
  quantity = request_payload['quantity']
  
  halt 400, json(message: 'Cantidad no proporcionada') unless quantity

  product = ProductService.find_by_id(params[:id])
  halt 404, json(message: 'Producto no encontrado') unless product

  begin
    ProductService.reduce_stock(params[:id], quantity)
    json message: 'Stock reducido correctamente'
  rescue StandardError => e
    halt 400, json(message: e.message)
  end
end





# Endpoint para crear una transacción
post '/transactions' do
  request_payload = JSON.parse(request.body.read)
  response = TransactionService.create_transaction(request_payload)
  halt 404, json(message: response[:error]) if response[:error]
  json response
end

# Endpoint para procesar un pago
post '/transactions/pay' do
  request_payload = JSON.parse(request.body.read)
  
  required_fields = %w[transaction_id expiration_time customer_data shipping_address amount_in_cents currency payment_method redirect_url]
  missing_fields = required_fields - request_payload.keys
  halt 400, json(message: "Faltan los siguientes campos: #{missing_fields.join(', ')}") unless missing_fields.empty?

  response = TransactionService.process_payment(request_payload)
  halt 500, json(message: response[:error]) if response[:error]
  json response
end


# Endpoint para consultar una transacción
get '/transactions/:id' do
  transaction = TransactionService.get_transaction_details(params[:id])
  halt 404, json(message: 'Transacción no encontrada') unless transaction
  json transaction
end

# Endpoint para crear un cliente
post '/customers' do
  request_payload = JSON.parse(request.body.read)
  customer_id = CustomerService.create(request_payload)
  json message: 'Cliente creado exitosamente', customer_id: customer_id
end

# Endpoint para registrar una entrega
post '/deliveries' do
  request_payload = JSON.parse(request.body.read)

  result = TransactionService.register_delivery(request_payload)

  if result[:error]
   halt 404, json(message: result[:error])
  end
  json result
end


get '/transactions/:transaction_id/status' do
  transaction_id = params[:transaction_id]

  # Consultar el estado de la transacción en la API de Wompi
  result = TransactionService.get_transaction_status(transaction_id)

  if result[:error]
    halt 404, json(message: result[:error])
  end

  # Responder con el estado de la transacción
  json result
end

# Endpoint para listar transacciones con filtros opcionales
get '/transactions' do
  filters = {}

  # Filtrar por estado si está presente en los parámetros
  filters[:status] = params['status'] if params['status']

  # Filtrar por rango de fechas si están presentes en los parámetros
  if params['start_date'] && params['end_date']
    start_date = DateTime.parse(params['start_date'])
    end_date = DateTime.parse(params['end_date'])
    transactions = DB[:transactions].where(filters)
                                     .where(created_at: start_date..end_date)
                                     .all
  else
    transactions = DB[:transactions].where(filters).all
  end

  json transactions
end


post '/webhook/notifications' do
  request_body = JSON.parse(request.body.read)

  event = request_body['event']
  data = request_body['data']

  if event == 'transaction.updated'
    transaction_id = data['id']
    status = data['status']

    # Actualizar el estado de la transacción en la base de datos
    DB[:transactions].where(transaction_id: transaction_id).update(status: status)
    json message: "Transacción #{transaction_id} actualizada a estado #{status}"
  else
    halt 400, json(message: 'Evento no soportado')
  end
end
