#!/usr/bin/env ruby

# file: cryptocoin_fanboi.rb


require 'coinmarketcap'
require 'table-formatter'


class CryptocoinFanboi
  
  attr_reader :coins

  def initialize(watch: [])

    @watch = watch.map(&:upcase)
        
    @fields = %w(rank name price_usd price_btc percent_change_1h 
          percent_change_24h percent_change_7d)
          
    @labels = %w(Rank Name USD BTC) + ['% 1hr:', '% 24hr:', '% 1 week:']
    @coins = fetch_coinlist(watch: @watch)

  end
  
  def coin_abbreviations()
    @coins.map {|x| "%s (%s)" % [x['name'], x['symbol']] }
  end
  
  alias abbreviations coin_abbreviations


  # View the coins with the largest gains in the past hour
  #  
  def now(limit: 5, markdown: false)

    TableFormatter.new(source: top_coins('1h', limit: limit), 
                       labels: @labels, markdown: markdown).display    
  end    

  # View the coins with the largest gains this week (past 7 days)
  #  
  def this_week(limit: 5, markdown: false)    
    
    TableFormatter.new(source: top_coins(limit: limit), 
                       labels: @labels, markdown: markdown).display    
    #top_coins(limit: limit)
  end
  
  alias week this_week
  
  # View the coins with the largest gains today (past 24 hours)
  #
  def today(limit: 5, markdown: false)
    
    TableFormatter.new(source: top_coins('24h', limit: limit), 
                       labels: @labels, markdown: markdown).display        
  end      

  def to_s(limit: nil, markdown: false, watch: @watch)
        
    coins = fetch_coinlist(limit: limit, watch: watch).map do |coin|

      @fields.map {|x| coin[x] }

    end

    TableFormatter.new(source: coins, labels: @labels, markdown: markdown).display

  end

  private

  def fetch_coinlist(limit: nil, watch: [])

    a = JSON.parse(Coinmarketcap.coins.body)    
    coins = watch.any? ? a.select {|x| watch.include? x['symbol']} : a    
    limit ? coins.take(limit) : coins
    
  end
  
  def top_coins(period='7d', limit: 5)
    
    @coins.sort_by {|x| -x['percent_change_' + period].to_f}.take(limit).map \
        {|coin| @fields.map {|x| coin[x] }}
  end  

end


if __FILE__ == $0 then

  ccf = CryptocoinFanboi.new
  puts ccf.to_s

end
