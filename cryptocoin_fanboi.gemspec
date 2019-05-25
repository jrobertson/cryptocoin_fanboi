Gem::Specification.new do |s|
  s.name = 'cryptocoin_fanboi'
  s.version = '0.6.0'
  s.summary = 'A coinmarketcap wrapper which makes it convenient to display ' +
      'the top 5 cryptocurrencies as listed on https://coinmarketcap.com.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/cryptocoin_fanboi.rb']
  s.add_runtime_dependency('colored', '~> 1.2', '>=1.2')
  s.add_runtime_dependency('chronic', '~> 0.10', '>=0.10.2')
  s.add_runtime_dependency('coinmarketcap', '~> 0.3', '>=0.3.0')
  s.add_runtime_dependency('coinmarketcap_lite', '~> 0.1', '>=0.1.0')
  s.add_runtime_dependency('table-formatter', '~> 0.7', '>=0.7.0')
  s.add_runtime_dependency('rexle', '~> 1.5', '>=1.5.1') 
  s.add_runtime_dependency('kramdown', '~> 2.1', '>=2.1.0') 
  s.add_runtime_dependency('justexchangerates', '~> 0.3', '>=0.3.4')
  s.signing_key = '../privatekeys/cryptocoin_fanboi.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/cryptocoin_fanboi'
end
