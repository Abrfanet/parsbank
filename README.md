# ParsBank
==============

[![Gem Version](https://badge.fury.io/rb/parsbank.svg)](https://rubygems.org/gems/parsbank)  
![Build Status](https://github.com/abrfanet/ParsBank/workflows/CI/badge.svg)

**ParsBank Gateway** is a Ruby gem designed to integrate with WSDL and JSON APIs of all payments methods such as cryptocurrency platforms (e.g., Bitcoin, USDT), and traditional payment platforms like Stripe and PayPal or private banks such as Troy bank or persians banks. This gem leverages **SOAP** and **Faraday** libraries, optimized for multiple retries during connection failures or timeouts. Additionally, it includes a proxy wrapper for connecting to core banks via MITM (man-in-the-middle) servers.

---

## Installation

### Using Bundler
Add ParsBank to your application's Gemfile and install it with:

```bash
$ bundle add ParsBank
```

### Without Bundler
Install the gem directly:

```bash
$ gem install ParsBank
```

### For Sinatra Applications
Include the gem in your Gemfile:

```ruby
gem "ParsBank"
```

Then install it with:

```bash
$ bundle install
```

---

## Usage

### Step 1: Configure ParsBank
Create a configuration file in `config/initializers` (e.g., `config/initializers/pars_bank.rb`):

```ruby
ParsBank.configuration do |config|
  config.callback_url = 'https://example.com/CallBack' # Your callback URL
  config.debug = false                                 # Enable logging (Rails logs and STDOUT)
  config.sandbox = false                               # Simulate requests and auto-approve callbacks
  config.webhook = 'https://yoursite.com/income-webhook?title=TITLE&message=MESSAGE' # Transaction notification webhook
  config.webhook_method = 'GET'                        # Webhook HTTP method (GET or POST)
  config.mitm_server = 'https://your-mitm-server.com'  # MITM server location
  config.secrets_path = Rails.root.join('config/bank_secrets.yaml') # Path to bank credentials (e.g., merchant ID, tokens)

  # Web Panel Configuration
  config.webpanel_path = '/parsbank'                   # Web panel path
  config.username = ENV['PARSBANK_USERNAME']           # Web panel username
  config.password = ENV['PARSBANK_PASSWORD']           # Web panel password
  config.allowed_ips = ['192.168.10.10']               # Restrict access by IP (use '*' to allow all)
  config.allow_when = ->(username, password) {         # Authentication using a Rails model
    user = User.find_by(username: username)
    user&.authenticate(password) && user.admin?
  }
  config.captcha = false                               # Enable CAPTCHA for security
  config.model = Transaction                          # Define transaction model (must include fields like amount, status, etc.)
end
```

---

### Step 2: Use ParsBank in Your Controller

Use the `get_redirect_from` method to generate a redirect form for users:

```ruby
class CartController < ApplicationController
  # @INPUT fiat_amount: can be dollars or rials
  # @INPUT crypto_amount: can be crypto assets amount like 0.0005
  # @INPUT real_amount: When use crypto or Rials can use dollar instead amount of crypto (E.G 100 dollar equal 0.005 bitcoin)
  # @INPUT description(required): Explain transaction details
  # @INPUT bank: Select specific bank or payment method like 'bsc-binance', 'nobitex', 'zarinpal', 'perfect-money'
  # @INPUT tags: Used for call which payments method such as ['crypto','rls','dollar','persian-banks','russian-banks']
  # @OUTPUT get_redirect_from: an javascript code for redirect user to gateways
  def redirect_to_parsbank
    form = ParsBank.get_redirect_from(fiat_amount: '10', description: 'Charge Account')
    render html: form
  end

  # @DESC: Shortcode for get all of enabled paymetns methods
  # @INPUT tags(Optional): ['crypto','rls','dollar','persian-banks','russian-banks']
  # @OUTPUT gateways_list_shortcode: List of all banks with name and logo with ul wrapper as html
  def choose_payment
    @payments_list_available_shortcode = ParsBank.gateways_list_shortcode
  end

  # @DESC: Parse all returned params from banks for verify transaction
  # @OUTPUT verify_transaction: Return transaction status as json like {status: 200, message: 'Payment Successfull'}
  def callback
    @parsbank_verifier= ParsBank.verify_transaction
    if @parsbank_verifier[:status] == 200
      flash[:success]= @parsbank_verifier[:message]
      redirect_to Something_path
    else
      flash[:error]= @parsbank_verifier[:message]
      redirect_to Something_path
    end
  end


end
```

---

## ParsBank Amazing Web

ParsBank comes with a built-in **web dashboard** for managing transactions and configurations visually. The dashboard includes:
- A beautiful interface with **Canva graphs** for transaction analysis.
- Tools for campaign improvements and data-driven decisions.

### Security Notice
Ensure that you apply CIS and other hardening rules to secure your bank credentials and virtual accounts (e.g., Binance) when using ParsBank Web.

---

### Setup for ParsBank Web

#### Method 1: Isolated Docker Container
**Requirements**:
- Docker
- Nginx or Apache (for reverse proxy)
- Resources: Adequate CPU, RAM, and modern storage for concurrent operations.

**Steps**:
1. Clone the repository:
   ```bash
   git clone https://github.com/Abrfanet/parsbank-web
   ```
2. Follow the repository's setup instructions.

#### Method 2: Inside a Rails Application
Include the web dashboard gem in your Rails app (refer to ParsBank Web documentation).

---

## 👨🏻‍💻 Development

We currently do not accept pull requests. Please report any issues in the [GitHub Issues section](https://github.com/abrfanet/ParsBank/issues). Also If you live in countries with specific payment systems, such as Russia (MIR Card), Germany, Turkey (Troy Card), or others, we warmly welcome you to join us as a developer or contributor. Your expertise and perspective can help us better support diverse payment ecosystems(We support you with PAGs users & CPC ⭐).

---

## 💖 Support This Project

If you find this project helpful and would like to support its development, consider making a donation. Your contributions help maintain and improve this project. Thank you for your generosity! 🙏

### Donate USDT (Tether)
- **USDT (ERC-20):** `0x2028f409a42413076665231e209896bbe0221d64`
- **USDT (TRC-20):** `TNtLkdy2FAKKBGJ4F8ij2mppWpjkB8GULy`
- **USDT (BEP-20):** `0x2028f409a42413076665231e209896bbe0221d64`


### Donate BTC (Bitcoin)
- **BSC (BEP-20):** `0x2028f409a42413076665231e209896bbe0221d64`



## 🚀 Premium Features

This project offers **premium features** to enhance your experience and support ongoing development. By contributing, you'll gain access to advanced capabilities while helping sustain and improve this project. 🙌

#### 🔐 How to Access Premium Features
1. **Make a Contribution**: 
   - Pay 29 USDT to one of the wallet addresses below(Annualy).
2. **Send Proof of Payment**: 
   - Email your transaction details to `info@abrfa.net` or submit them via a dedicated contact form.
3. **Receive Access**: 
   - Upon verification, you'll receive instructions to access the premium features.

#### 💳 USDT Wallet Addresses
- **USDT (ERC-20):** `0x2028f409a42413076665231e209896bbe0221d64`
- **USDT (TRC-20):** `TNtLkdy2FAKKBGJ4F8ij2mppWpjkB8GULy`

#### 🔥 Available Premium Features
- Feature 1: **Advanced Analytics**  
- Feature 2: **Customizable Reports**  
- Feature 3: **Priority Support**
- Feature 4: **ParsBank Web Access**

> **Note**: Contributions are used to maintain and improve this project. Thank you for your support! 🙏

## Contributing

Bug reports and feature requests are welcome at [ParsBank GitHub repository](https://github.com/abrfanet/ParsBank).
