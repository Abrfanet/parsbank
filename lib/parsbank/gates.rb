module Parsbank
  class Gates
    def self.logo
      File.read "#{__dir__}/#{self.class.name.split('::').last.downcase}/logo.svg"
    end

    def default_config(key)
      Parsbank.load_secrets_yaml[self.class.name.split('::').last.downcase][key.to_s]
    end

    def redirect_loaders
      File.read "#{__dir__}/../tmpl/_loader.html"
    end
  end
end
