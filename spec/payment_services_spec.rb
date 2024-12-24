require 'spec_helper'
require_relative '../lib/services/payment_service'
require_relative '../app'

RSpec.describe PaymentService do
  describe '.process_payment' do
    it 'procesa un pago exitosamente' do
      params = {
        reference: 'test_ref',
        amount_in_cents: 10000,
        currency: 'COP',
        customer_email: 'test@example.com',
        payment_method: { type: 'CARD', token: 'test_token' },
        redirect_url: 'https://example.com',
        customer_data: { full_name: 'John Doe' },
        shipping_address: { address_line_1: '123 Street', city: 'City' }
      }

      acceptance_token = 'mock_acceptance_token'
      allow(PaymentService).to receive(:get_acceptance_token).and_return(acceptance_token)
      allow(PaymentService).to receive(:generate_signature).and_return('mock_signature')

      uri = URI("#{WOMPI_CONFIG[:sandbox_url]}/transactions")
      response = double(body: { data: { status: 'APPROVED' } }.to_json)
      allow(PaymentService).to receive(:send_post_request).and_return(response)

      result = PaymentService.process_payment(params)

      expect(result['data']['status']).to eq('APPROVED')
    end

    it 'lanza un error si no puede obtener el acceptance_token' do
      allow(PaymentService).to receive(:get_acceptance_token).and_return(nil)

      params = {
        reference: 'test_ref',
        amount_in_cents: 10000,
        currency: 'COP',
        customer_email: 'test@example.com'
      }

      expect { PaymentService.process_payment(params) }.to raise_error(RuntimeError, 'Error al obtener el acceptance_token')
    end
  end

  describe '.get_acceptance_token' do
    it 'obtiene un acceptance_token exitosamente' do
      response_body = {
        data: {
          presigned_acceptance: {
            acceptance_token: 'mock_acceptance_token'
          }
        }
      }.to_json

      uri = URI("#{WOMPI_CONFIG[:sandbox_url]}/merchants/#{WOMPI_CONFIG[:public_key]}")
      response = double(body: response_body)
      allow(Net::HTTP).to receive(:get_response).with(uri).and_return(response)

      result = PaymentService.get_acceptance_token

      expect(result).to eq('mock_acceptance_token')
    end

    it 'retorna nil si no encuentra un acceptance_token' do
      response_body = { data: {} }.to_json

      uri = URI("#{WOMPI_CONFIG[:sandbox_url]}/merchants/#{WOMPI_CONFIG[:public_key]}")
      response = double(body: response_body)
      allow(Net::HTTP).to receive(:get_response).with(uri).and_return(response)

      result = PaymentService.get_acceptance_token

      expect(result).to be_nil
    end
  end

  describe '.generate_signature' do
    it 'genera una firma correctamente sin expiration_time' do
      reference = 'test_ref'
      amount_in_cents = 10000
      currency = 'COP'
      integrity_secret = 'test_secret'

      expected_signature = Digest::SHA256.hexdigest("#{reference}#{amount_in_cents}#{currency}#{integrity_secret}")

      result = PaymentService.generate_signature(reference, amount_in_cents, currency, integrity_secret)

      expect(result).to eq(expected_signature)
    end

    it 'genera una firma correctamente con expiration_time' do
      reference = 'test_ref'
      amount_in_cents = 10000
      currency = 'COP'
      integrity_secret = 'test_secret'
      expiration_time = '2024-12-31T23:59:59Z'

      expected_signature = Digest::SHA256.hexdigest("#{reference}#{amount_in_cents}#{currency}#{expiration_time}#{integrity_secret}")

      result = PaymentService.generate_signature(reference, amount_in_cents, currency, integrity_secret, expiration_time)

      expect(result).to eq(expected_signature)
    end
  end
end

RSpec.describe 'Payment Service API' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe 'POST /transactions/pay' do
    let(:valid_payload) do
      {
        transaction_id: 1,
        expiration_time: '2024-12-31T23:59:59Z',
        customer_data: {
          name: 'John Doe',
          email: 'john.doe@example.com'
        },
        shipping_address: '123 Main Street, Springfield',
        amount_in_cents: 10000,
        currency: 'USD',
        payment_method: 'credit_card',
        redirect_url: 'http://localhost:3000/thank_you'
      }.to_json
    end

    let(:invalid_payload) do
      {
        transaction_id: 1,
        expiration_time: '2024-12-31T23:59:59Z',
        # Falta customer_data, shipping_address, etc.
      }.to_json
    end

    it 'procesa un pago exitosamente con un payload válido' do
      header 'Content-Type', 'application/json'
      post '/transactions/pay', valid_payload

      expect(last_response.status).to eq(200)
      response_body = JSON.parse(last_response.body)
      expect(response_body['message']).to include('Pago procesado exitosamente')
    end

    it 'retorna un error 400 si faltan campos obligatorios' do
      header 'Content-Type', 'application/json'
      post '/transactions/pay', invalid_payload

      expect(last_response.status).to eq(400)
      response_body = JSON.parse(last_response.body)
      expect(response_body['message']).to include('Faltan los siguientes campos')
    end

    it 'retorna un error 500 si ocurre un problema interno' do
      allow(TransactionService).to receive(:process_payment).and_return({ error: 'Error interno del servidor' })

      header 'Content-Type', 'application/json'
      post '/transactions/pay', valid_payload

      expect(last_response.status).to eq(500)
      response_body = JSON.parse(last_response.body)
      expect(response_body['message']).to eq('Error interno del servidor')
    end
  end
end
