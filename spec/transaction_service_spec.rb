require 'spec_helper'
require_relative '../lib/services/transaction_service'

RSpec.describe TransactionService do
  describe '.get_transaction_status' do
    it 'retorna el estado de una transacción existente' do
      transaction_id = '123456'
      allow(DB[:transactions]).to receive(:[]).and_return({ transaction_id: transaction_id, status: 'APPROVED' })
      result = TransactionService.get_transaction_status(transaction_id)
      expect(result[:status]).to eq('APPROVED')
    end

    it 'retorna un error si la transacción no existe' do
      transaction_id = 'invalido'
      allow(DB[:transactions]).to receive(:[]).and_return(nil)
      result = TransactionService.get_transaction_status(transaction_id)
      expect(result[:error]).to eq('Transacción no encontrada localmente')
    end
  end
end

RSpec.describe TransactionService do
  describe '.create_transaction' do
    it 'crea una transacción con éxito' do
      payload = {
        'product_id' => 1,
        'customer_email' => 'test@example.com',
        'payment_method' => 'CREDIT_CARD',
        'reference' => 'test_ref'
      }

      product = { id: 1, price: 100.0 }
      allow(DB[:products]).to receive(:[]).with(id: payload['product_id']).and_return(product)
      allow(PaymentService).to receive(:get_acceptance_token).and_return('mock_token')
      allow(PaymentService).to receive(:generate_signature).and_return('mock_signature')
      allow(PaymentService).to receive(:send_post_request).and_return(double(body: { data: { id: 'txn_12345' } }.to_json))
      allow(DB[:transactions]).to receive(:insert)

      result = TransactionService.create_transaction(payload)

      expect(result[:transaction_id]).to eq('txn_12345')
      expect(result[:amount_in_cents]).to eq(10000)
      expect(result[:reference]).to eq('test_ref')
    end

    it 'retorna un error si el producto no se encuentra' do
      payload = { 'product_id' => 999 }
      allow(DB[:products]).to receive(:[]).with(id: payload['product_id']).and_return(nil)

      result = TransactionService.create_transaction(payload)

      expect(result[:error]).to eq('Producto no encontrado')
    end

    it 'retorna un error si no puede obtener el acceptance_token' do
      payload = { 'product_id' => 1 }
      product = { id: 1, price: 100.0 }
      allow(DB[:products]).to receive(:[]).with(id: payload['product_id']).and_return(product)
      allow(PaymentService).to receive(:get_acceptance_token).and_return(nil)

      expect { TransactionService.create_transaction(payload) }.to raise_error(RuntimeError, 'Error al obtener el acceptance_token')
    end
  end
end

RSpec.describe TransactionService do
  describe '.process_payment' do
    it 'procesa un pago exitosamente' do
      payload = { 'transaction_id' => 'txn_12345', 'payment_method' => 'CREDIT_CARD', 'customer_email' => 'test@example.com' }
      transaction = { transaction_id: 'txn_12345', amount: 10000, product_id: 1 }
      response = { 'data' => { 'status' => 'APPROVED' } }

      allow(DB[:transactions]).to receive(:[]).with(transaction_id: payload['transaction_id']).and_return(transaction)
      allow(PaymentService).to receive(:process_payment).and_return(response)
      allow(DB[:products]).to receive(:where).and_return(double(update: true))
      allow(DB[:transactions]).to receive(:where).and_return(double(update: true))

      result = TransactionService.process_payment(payload)

      expect(result['data']['status']).to eq('APPROVED')
    end

    it 'retorna un error si la transacción no se encuentra' do
      payload = { 'transaction_id' => 'invalid' }
      allow(DB[:transactions]).to receive(:[]).with(transaction_id: payload['transaction_id']).and_return(nil)

      result = TransactionService.process_payment(payload)

      expect(result[:error]).to eq('Transacción no encontrada')
    end
  end
end

RSpec.describe TransactionService do
  describe '.register_delivery' do
    it 'registra una entrega exitosamente' do
      payload = { 'transaction_id' => 'txn_12345', 'address' => '123 Street, City', 'status' => 'DELIVERED' }
      transaction = { id: 1, transaction_id: 'txn_12345' }

      allow(DB[:transactions]).to receive(:[]).with(transaction_id: payload['transaction_id']).and_return(transaction)
      allow(DB[:deliveries]).to receive(:insert).and_return(101)

      result = TransactionService.register_delivery(payload)

      expect(result[:delivery_id]).to eq(101)
    end

    it 'retorna un error si la transacción no se encuentra' do
      payload = { 'transaction_id' => 'invalid', 'address' => '123 Street, City' }
      allow(DB[:transactions]).to receive(:[]).with(transaction_id: payload['transaction_id']).and_return(nil)

      result = TransactionService.register_delivery(payload)

      expect(result[:error]).to eq('Transacción no encontrada')
    end
  end
end
