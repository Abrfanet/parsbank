# Saman

Saman Bank Gateway

An Ruby Gem Library for integrate with WSDL of Saman Bank, In this Gem we use soap lib as main dependency also we tunned soap for multile retries when failed connections or request, in the end we work on proxy wrapper for connct to core bank with MITM server 

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add saman

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install saman

In sinatra application just add `gem "saman"` on your Gemfile and install with `bundle install`

## Usage

First step:

in config/initilizers create new config file:
```
#config/initilizers/saman.rb


Saman.configuration do |config|

config.merchant_id = 'YOUR_GAINED_MID_FROM_SAMAN'
config.redirect_url = 'YOUR CALLBACK LOCATION LIKE https://example.com/samaCallBack'

config.debug = false # Enable Log Tracking
config.sandbox = false # Enable Simulation for your requst also approve callback without verification
config.webhook = "https://bale.ai/@Bot" # Webhook for notify any success transactions or errors on cominiucate with Core Bank

config.mitm = 'YOUR_MITM_SERVER_LOCATION as HTTP or HTTPS'

end

```


Inside of your controller call Token action and get url for redirect user to Gateway page

```
class ApplicationController > Cart 
    def redirect_to_saman
        form = Saman.get_redirect_from(amount: 100000, description: 'Charge Account')
        render html: form
    end
end
```


## Development

We don't accept any pull request, just use issue section

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/saman.
