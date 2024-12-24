require 'net/http'
require 'json'
require 'digest'
require_relative '../../config/wompi'

class PaymentService
  def self.process_payment(params)
    uri = URI("#{WOMPI_CONFIG[:sandbox_url]}/transactions")

    # Obtener el token de aceptación
    acceptance_token = get_acceptance_token 
    raise "Error al obtener el acceptance_token" if acceptance_token.nil?
   

    # Generar la firma
    signature = generate_signature(
      params[:reference],
      params[:amount_in_cents],
      params[:currency],
      WOMPI_CONFIG[:integrity_secret],
      params[:expiration_time]
     
    )
    

    # Configurar la solicitud
    request_body = {
      acceptance_token: acceptance_token,
      amount_in_cents: params[:amount_in_cents],
      currency: params[:currency],
      customer_email: params[:customer_email],
      reference: params[:reference],
      expiration_time: params[:expiration_time],
      payment_method: params[:payment_method],
      redirect_url: params[:redirect_url],
      customer_data: params[:customer_data],
      shipping_address: params[:shipping_address],
      signature: signature
    }


    response = send_post_request(uri, request_body)
    puts "Respuesta del servicio de pago: #{response.body}"

    JSON.parse(response.body)
  end

  def self.get_acceptance_token
    uri = URI("#{WOMPI_CONFIG[:sandbox_url]}/merchants/#{WOMPI_CONFIG[:public_key]}")
    response = Net::HTTP.get_response(uri)
    JSON.parse(response.body).dig('data', 'presigned_acceptance', 'acceptance_token')
  end
  
  

  def self.generate_signature(reference, amount_in_cents, currency, integrity_secret, expiration_time = nil)
    data = expiration_time ? 
             "#{reference}#{amount_in_cents}#{currency}#{expiration_time}#{integrity_secret}" :
             "#{reference}#{amount_in_cents}#{currency}#{integrity_secret}"
    
    puts "Datos para generar la firma: #{data}"

    puts "Referencia: #{reference}"
    puts "Monto en centavos: #{amount_in_cents}"
    puts "Moneda: #{currency}"
    puts "Fecha de expiración: #{expiration_time}" if expiration_time
    puts "Secreto de integridad: #{integrity_secret}"
    Digest::SHA256.hexdigest(data)
  end

  private

  def self.send_post_request(uri, body)
    request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    request['Authorization'] = "Bearer #{WOMPI_CONFIG[:private_key]}"
    request.body = body.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.request(request)
  end

  def self.send_get_request(uri)
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{WOMPI_CONFIG[:public_key]}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.request(request)
  end
end
