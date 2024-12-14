
class Configuration
    attr_accessor :callback_url, :debug, :sandbox,
                  :webhook,
                  :webhook_method,
                  :mitm_server,
                  :secrets_path,
                  :min_amount,
                  :webpanel_path,
                  :username,
                  :password,
                  :allowed_ips,
                  :allow_when,
                  :captcha,
                  :model

    def initialize
      @callback_url = nil
      @debug = false
      @sandbox = false
      @webhook = nil
      @webhook_method = "POST"
      @mitm_server = nil
      @secrets_path = nil
      @min_amount = 10000
      @webpanel_path = nil
      @username = nil
      @password = nil
      @allowed_ips = ['*']
      @allow_when = -> { true }
      @captcha = false
      @model = nil
    end
  end