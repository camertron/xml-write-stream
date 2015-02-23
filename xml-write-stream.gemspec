$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'xml-write-stream/version'

Gem::Specification.new do |s|
  s.name     = "xml-write-stream"
  s.version  = ::XmlWriteStream::VERSION
  s.authors  = ["Cameron Dutro"]
  s.email    = ["camertron@gmail.com"]
  s.homepage = "http://github.com/camertron"

  s.description = s.summary = "An easy, streaming way to generate XML."

  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true

  s.require_path = 'lib'
  s.files = Dir["{lib,spec}/**/*", "Gemfile", "History.txt", "README.md", "Rakefile", "xml-write-stream.gemspec"]
end
