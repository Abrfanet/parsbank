module Parsbank
  class Gates

    def self.logo
      File.read "#{__dir__}/#{self.name.split('::').last.downcase}/logo.svg"
    end

    def default_config(key)
      Parsbank.load_secrets_yaml[self.name.split('::').last.downcase][key.to_s]
    end

  end
end
