# frozen_string_literal: true

require_relative 'lib/parsbank/version'

Gem::Specification.new do |spec|
  spec.name = 'parsbank'
  spec.version = Parsbank::VERSION
  spec.authors = ['Mohammad Mahmoodi']
  spec.email = ['mm580486@gmail.com']

  spec.summary = 'An powerfull gem for lunch your smart gateways'
  spec.description = 'Focus on your ecommerce we handle your payments.'
  spec.homepage = 'https://github.com/Abrfanet'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/Abrfanet/parsbank'
  spec.metadata['changelog_uri'] = 'https://changelog.md/ParsBank'
  spec.license = 'WTFPL'
  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ web/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.add_dependency 'activerecord'
  spec.add_dependency 'faraday'
  spec.add_dependency 'faraday_middleware'
  spec.add_dependency 'savon'
  # spec.add_dependency 'activerecord'


  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']


end
