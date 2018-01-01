Gem::Specification.new do |s|
  s.name = 'cryptocoin_fanboi'
  s.version = '0.1.0'
  s.summary = 'A coinmarketcap wrapper which makes it convenient to display the top 5 crypto currencies as listed on https://coinmarketcap.com.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/cryptocoin_fanboi.rb']
  s.add_runtime_dependency('coinmarketcap', '~> 0.2', '>=0.2.4')
  s.add_runtime_dependency('table-formatter', '~> 0.4', '>=0.4.2') 
  s.signing_key = '../privatekeys/cryptocoin_fanboi.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/cryptocoin_fanboi'
end
