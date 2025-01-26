module Parsbank
  class TransactionRequest
    def self.create(args = {})
      bank = fetch_bank(args)
      validate_bank(bank)

      description = args.fetch(:description)
      callback_url = generate_callback_url(bank, description)

      crypto_amount, fiat_amount, real_amount = fetch_amounts(args)
      validate_amounts(bank, crypto_amount, fiat_amount, real_amount)

      transaction = initialize_transaction(args, description, fiat_amount, crypto_amount, bank, callback_url)
      process_gateway(bank, transaction, description, callback_url, crypto_amount, fiat_amount, args)

      { transaction: transaction, html_form: @result }
    end

    def self.fetch_bank(args)
      args.fetch(:bank, Parsbank.available_gateways_list.keys.sample)
    end

    def self.validate_bank(bank)
      selected_bank = Parsbank.available_gateways_list[bank]
      raise "Bank not enabled or not exists in #{Parsbank.configuration.secrets_path}: #{bank}" unless selected_bank
    end

    def self.generate_callback_url(bank, _description)
      selected_bank = Parsbank.available_gateways_list[bank]
      "#{selected_bank['callback_url'] || Parsbank.configuration.callback_url}&bank_name=#{bank}"
    end

    def self.fetch_amounts(args)
      [
        args.fetch(:crypto_amount, nil),
        args.fetch(:fiat_amount, nil),
        args.fetch(:real_amount, nil)
      ]
    end

    def self.validate_amounts(bank, crypto_amount, fiat_amount, real_amount)
      raise 'Amount fields are empty: crypto_amount OR fiat_amount OR real_amount' if [crypto_amount, fiat_amount,
                                                                                       real_amount].all?(&:nil?)

      tags = $SUPPORTED_PSP[bank]['tags']
      if tags.include?('crypto') && crypto_amount.nil? && real_amount.nil?
        raise "#{bank} needs crypto_amount or real_amount"
      end

      return unless tags.include?('rial') && fiat_amount.nil? && real_amount.nil?

      raise "#{bank} needs fiat_amount or real_amount"
    end

    def self.initialize_transaction(args, description, fiat_amount, crypto_amount, bank, callback_url)
      model_class = Parsbank.configuration.model || 'Transaction'
      @transaction= Object.const_get(model_class).new(
        description: description,
        amount: fiat_amount || crypto_amount,
        gateway: bank,
        callback_url: callback_url,
        status: 'start',
        user_id: args.fetch(:user_id, nil),
        cart_id: args.fetch(:cart_id, nil),
        local_id: args.fetch(:local_id, nil),
        ip: args.fetch(:ip, nil)
      )
      @transaction.save

      @transaction
    end

    def self.process_gateway(bank, transaction, description, callback_url, crypto_amount, fiat_amount, args)
      case bank
      when 'mellat'
        process_mellat(transaction, description, callback_url, fiat_amount)
      when 'zarinpal'
        process_zarinpal(transaction, description, callback_url, fiat_amount)
      when 'zibal'
        process_zibal(description, callback_url, fiat_amount)
      when 'bscbitcoin'
        process_bscbitcoin(transaction, description, crypto_amount, args)
      else
        raise "Unsupported gateway: #{bank}"
      end
    end

    def self.process_mellat(transaction, description, callback_url, fiat_amount)
      mellat = Parsbank::Mellat.new(
        amount: fiat_amount,
        additional_data: description,
        callback_url: callback_url,
        orderId: transaction.id
      )
      mellat.call
      transaction.update!(gateway_response: mellat.response, unit: 'irr')
      @result = mellat.redirect_form
    end

    def self.process_zarinpal(transaction, description, callback_url, fiat_amount)
      zarinpal = Parsbank::Zarinpal.new(
        amount: fiat_amount,
        additional_data: description,
        callback_url: callback_url
      )
      zarinpal.call
      transaction.update!(
        gateway_response: zarinpal.response,
        track_id: zarinpal.ref_id,
        unit: 'irt'
      )
      @result = zarinpal.redirect_form
    end

    def self.process_zibal(description, callback_url, fiat_amount)
      zibal = Parsbank::Zibal.new(
        amount: fiat_amount,
        additional_data: description,
        callback_url: callback_url
      )
      zibal.call
      @result = zibal.redirect_form
    end

    def self.process_bscbitcoin(transaction, description, crypto_amount, args)
      bscbitcoin = Parsbank::BscBitcoin.new(
        additional_data: description
      )
      convert_real_amount_to_assets if crypto_amount.nil? && args.key?(:real_amount)
      @result = bscbitcoin.generate_payment_address(amount: crypto_amount)
      transaction.update!(gateway_response: @result, unit: 'bitcoin')
    end
  end
end
