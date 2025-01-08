# ParsBank
==============

[![Gem Version](https://badge.fury.io/rb/parsbank.svg)](https://rubygems.org/gems/parsbank)
![Build](https://github.com/abrfanet/ParsBank/workflows/CI/badge.svg)


ParsBank Gateway

An Ruby Gem Library for integrate with WSDL and JSON of Persian Banks, In this Gem we use soap and faraday lib as main dependency also we tunned soap/faraday for multile retries when failed connections or request, in the end we work on proxy wrapper for connct to core bank with MITM server 

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add ParsBank

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install ParsBank

In sinatra application just add `gem "ParsBank"` on your Gemfile and install with `bundle install`

## Usage

First step:

in config/initilizers create new config file:
```
#config/initilizers/pars_bank.rb


ParsBank.configuration do |config|

    config.callback_url = 'YOUR CALLBACK LOCATION LIKE https://example.com/CallBack'

    config.debug = false # Enable Log Tracking with Rails.log and STDOUT

    config.sandbox = false # Enable Simulation for your requst also approve callback without verification

    config.webhook = "https://yoursite.com/income-webhook?title=TITLE&message=MESSAGE" # Webhook for notify any success transactions or errors on cominiucate with Core Bank
    config.webhook_method = 'GET' # or POST 

    config.mitm_server = 'YOUR_MITM_SERVER_LOCATION as HTTP or HTTPS'

    config.secrets_path = Rails.root.join('config/bank_secrets.yaml') #PATH OF YOUR BANKS CREDITS like merchant id, username, password or token

    config.min_amount = '10000' # as rials

    # WebPanel Config
    config.webpanel_path = '/parsbank'
    ## Basic Authentication
    config.username = ENV['PARSBANK_USERNAME']
    config.password = ENV['PARSBANK_PASSWORD']
    ## Authetication With IP source
    config.allowed_ips = ['192.168.10.10'] # add * to allow all ip
    ## Authentication with rails model
    config.allow_when = User.find_by(username: USERNAME).authenticate(PASSWORD) && User.find_by(username: USERNAME).admin?

    # Secure by captcha
    config.captcha = false

    # Model for store transactions
    # Transaction model should have amount, status, bank_name, callback_url, authority_code or anything you need
    config.model = Transaction 
    

end

```


Inside of your controller call Token action and get url for redirect user to Gateway page

```
class ApplicationController > Cart 
    def redirect_to_ParsBank
        form = ParsBank.get_redirect_from(amount: 100000, description: 'Charge Account')
        render html: form
    end
end
```



# ParsBank Amazing Web
With ParsBank Web You Can Access To Your Transactions and Config Files Visualy! Also You Get Beautifull Dashboard with Canva Graph For Analysis Your Transaction And Improve Your Campiagn And Important Decisions ⭐

```
Important Note: When Use ParsBank Web you should apply CIS rules and all harening rules for secure your credentials of banks and virtuals account like binance.
```

Get Ready For ParsBank Web Gem:

## Method 1 (Isolated Dockerfile)
Requrements:
    - Docker
    - Nginx or Apache Reverse Proxy for forward trafik to specific port
    - ParsBank Web use sinatra with Concurency so needs considerable resource like RAM, CPU or next-gen of Hard Drive
in first step clone git repository `git clone https://github.com/Abrfanet/parsbank-web`


## Method 2 (Inside of Rails App)

## Development

We don't accept any pull request, just use issue section

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ParsBank.
