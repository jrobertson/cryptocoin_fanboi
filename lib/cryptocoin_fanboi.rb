#!/usr/bin/env ruby

# file: cryptocoin_fanboi.rb


require 'colored'
require 'coinmarketcap'
require 'table-formatter'


class CryptocoinFanboi
  
  attr_reader :coins
  attr_accessor :colored

  def initialize(watch: [], colored: true)

    @colored = colored
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
    
    build_table top_coins('1h', limit: limit), markdown: markdown
    
  end    

  # View the coins with the largest gains this week (past 7 days)
  #  
  def this_week(limit: 5, markdown: false)    
    
    build_table top_coins(limit: limit), markdown: markdown

  end
  
  alias week this_week
  
  # View the coins with the largest gains today (past 24 hours)
  #
  def today(limit: 5, markdown: false)
    
    build_table top_coins('24h', limit: limit), markdown: markdown
    
  end      

  def to_s(limit: nil, markdown: false, watch: @watch)
        
    coins = fetch_coinlist(limit: limit, watch: watch).map do |coin|

      @fields.map {|x| coin[x] }

    end

    build_table coins, markdown: markdown

  end

  private
  
  def build_table(coins, markdown: markdown)

    s = TableFormatter.new(source: coins, labels: @labels, markdown: markdown)\
        .display
    
    return s if @colored == false
    
    a = s.lines
    
    body = a[3..-2].map do |line|
      
      fields = line.split('|')         
      a2 = fields[5..-2].map {|x| x[/^ +-/] ? x.red : x.green }            
      (fields[0..4] + a2 + ["\n"]).join('|')  

    end
    
    (a[0..2] + body + [a[-1]]).join
    
  end

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
