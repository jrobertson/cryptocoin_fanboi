#!/usr/bin/env ruby

# file: cryptocoin_fanboi


require 'coinmarketcap'
require 'table-formatter'


class CryptocoinFanboi

  def initialize()

    @tfo = TableFormatter.new
    @tfo.labels = %w(Name USD BTC) + ['% 24hr:', '% 1 week:']

  end

  def to_s(limit: 5, markdown: false)
    
    @tfo.source = fetch_coinlist limit: limit
    @tfo.display markdown: markdown

  end

  private

  def fetch_coinlist(limit: 5)

    coins = JSON.parse(Coinmarketcap.coins.body).take(limit).map do |coin|

      %w(name price_usd price_btc percent_change_24h percent_change_7d)\
        .map {|x| coin[x] }

    end

  end

end


if __FILE__ == $0 then

  ccf = CryptocoinFanboi.new
  puts ccf.to_s

end
