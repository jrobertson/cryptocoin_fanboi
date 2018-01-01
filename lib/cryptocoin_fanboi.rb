#!/usr/bin/env ruby

# file: cryptocoin_fanboi


require 'coinmarketcap'
require 'table-formatter'


class CryptocoinFanboi

  def initialize(watch: [])

    @watch = watch.map(&:upcase)
    
    @tfo = TableFormatter.new
    @tfo.labels = %w(Name USD BTC) + ['% 24hr:', '% 1 week:']
    @coins = fetch_coinlist(watch: @watch)

  end
  
  def coin_abbreviations()
    @coins.map {|x| "%s (%s)" % [x['name'], x['symbol']] }
  end
  
  alias abbreviations coin_abbreviations

  def to_s(limit: nil, markdown: false)
        
    coins = fetch_coinlist(limit: limit, watch: @watch).map do |coin|

      %w(name price_usd price_btc percent_change_24h percent_change_7d)\
        .map {|x| coin[x] }

    end

    @tfo.source = coins
    @tfo.display markdown: markdown

  end

  private

  def fetch_coinlist(limit: nil, watch: [])

    a = JSON.parse(Coinmarketcap.coins.body)    
    coins = watch.any? ? a.select {|x| watch.include? x['symbol']} : a    
    limit ? coins.take(limit) : coins
    
  end

end


if __FILE__ == $0 then

  ccf = CryptocoinFanboi.new
  puts ccf.to_s

end
