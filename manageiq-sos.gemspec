
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "manageiq/sos/version"

Gem::Specification.new do |spec|
  spec.name          = "manageiq-sos"
  spec.version       = Manageiq::Sos::VERSION
  spec.authors       = ["Keenan Brock"]
  spec.email         = ["keenan@thebrocks.net"]

  spec.summary       = %q{SOS report for manageiq systems}
  spec.description   = %q{Displays diagnostic information about manageiq systems}
  spec.homepage      = "https://github.com/kbrock/manageiq-sos/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
