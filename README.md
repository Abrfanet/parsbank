# ParsBank
==============

[![Gem Version](https://badge.fury.io/rb/parsbank.svg)](https://rubygems.org/gems/parsbank)  
![Build Status](https://github.com/abrfanet/ParsBank/workflows/CI/badge.svg)

**ParsBank Gateway** is a Ruby gem designed to integrate with WSDL and JSON APIs of Persian banks, cryptocurrency platforms (e.g., Bitcoin, USDT), and traditional payment platforms like Stripe and PayPal. This gem leverages **SOAP** and **Faraday** libraries, optimized for multiple retries during connection failures or timeouts. Additionally, it includes a proxy wrapper for connecting to core banks via MITM (man-in-the-middle) servers.

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
  def redirect_to_parsbank
    form = ParsBank.get_redirect_from(amount: 100_000, description: 'Charge Account')
    render html: form
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

## Development

We currently do not accept pull requests. Please report any issues in the [GitHub Issues section](https://github.com/abrfanet/ParsBank/issues).

---

## Contributing

Bug reports and feature requests are welcome at [ParsBank GitHub repository](https://github.com/abrfanet/ParsBank).
