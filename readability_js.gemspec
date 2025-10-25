# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'readability_js/version'

Gem::Specification.new do |spec|
  spec.name = "readability_js"
  spec.version = ReadabilityJs::VERSION
  spec.authors = ["Matthäus Beyrle"]
  spec.email = ["readability_js.gemspec@mail.magynhard.de"]
  spec.license = "MIT"

  spec.summary = %q{Clean up web pages and extract the main content, powered by Mozilla Readability}
  spec.description = %q{ReadabilityJs is a Ruby wrapper gem for the mozilla readability library to extract the main content from web pages. It uses the Nodo gem to run the JavaScript Readability library in a Node.js environment, allowing for efficient and accurate content extraction within Ruby applications.}
  spec.homepage = "https://github.com/magynhard/ruby-readability_js"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
            "public gem pushes."
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.0.0'

  # Runtime dependencies
  spec.add_runtime_dependency 'nodo', '~> 1.8'
  spec.add_runtime_dependency 'ostruct', '~> 0.6.3'
  spec.add_runtime_dependency 'reverse_markdown', '~> 3.0'
  spec.add_runtime_dependency 'nokogiri', '~> 1.18'

  # Development dependencies
  spec.add_development_dependency 'bundler', '>= 1.14'
  spec.add_development_dependency 'rake', '>= 10.0'
  spec.add_development_dependency 'rspec', '>= 3.0'
  spec.add_development_dependency 'colorize', '0.8.1'
  spec.add_development_dependency 'pry', '0.14.1'
end
