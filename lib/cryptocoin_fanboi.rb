#!/usr/bin/env ruby

# file: cryptocoin_fanboi.rb


require 'psych'
require 'colored'
require 'coinmarketcap'
require 'table-formatter'


class CryptocoinFanboi
  
  attr_reader :coins, :all_coins
  attr_accessor :colored

  def initialize(watch: [], ignore: [], colored: true, debug: false)

    @colored, @debug = colored, debug
    @watch= watch.map(&:upcase)
    @ignore = ignore.map(&:upcase)
        
    @fields = %w(rank name price_usd price_btc percent_change_1h 
          percent_change_24h percent_change_7d)

    @year = Time.now.year.to_s          
    @labels = %w(Rank Name USD BTC) + ['% 1hr:', '% 24hr:', 
                                       '% 1 week:', '% ' + @year + ':']
    @coins = fetch_coinlist()

    
    # check for the local cache file containing a record of currency 
    # prices from the start of the year
    
    cache_filename = 'cryptocoin_fanboi.yaml'    
    
    if File.exists? cache_filename then
      
      #load the file
      h = Psych.load File.read(cache_filename)
      puts 'h.key.first: ' + h.keys.first.inspect if @debug
      puts '@year: ' + @year.inspect if @debug
      @growth = (h.keys.first == @year) ? h[@year] : fetch_growth(@all_coins)
      puts '@growth: ' + @growth.inspect if @debug
    else
      
      # fetch the currency prices from the start of the year
      @growth = fetch_growth(@all_coins)      
      File.write cache_filename, {@year => @growth}.to_yaml
      
    end
    
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

  def to_s(limit: nil, markdown: false)
        
    coins = fetch_coinlist(limit: limit).map do |coin|

      @fields.map {|x| coin[x] }

    end

    build_table coins, markdown: markdown

  end

  private
  
  def build_table(a, markdown: markdown)
        
    coins = a.map do |x|
      @growth.has_key?(x[1]) ? x + [@growth[x[1]].to_s] : x
    end
    
    puts 'coins: ' + coins.inspect if @debug
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

  def fetch_coinlist(limit: nil)

    @all_coins = JSON.parse(Coinmarketcap.coins.body)    
    
    a = if @watch.any? then
      @all_coins.select {|x| @watch.include? x['symbol']}
    elsif @ignore.any?
      @all_coins.reject {|x| @ignore.include? x['symbol']}
    else
      @all_coins    
    end    

    limit ? a.take(limit) : a
    
  end

  # fetch the currency prices from the start of the year 
  #
  def fetch_growth(coins)

    puts 'fetching growth ...' if @debug
    
    coins.inject({}) do |r, x| 

      day1 = @year + '0101'
      puts 'x: ' + x['name'].inspect if @debug
      begin
        a = Coinmarketcap.get_historical_price(x['name'].gsub(/ /,'-'), 
                                               day1, day1)
      rescue
        puts 'warning : ' + x['name'].inspect + ' ' + ($!).inspect        
      end

      if a and a.any? then
        latest_day, year_start = x['price_usd'].to_f, a[0][:close]
        r.merge({x['name'] => (100.0 / (year_start / 
                                        (latest_day - year_start))).round(2)})
      else
        r
      end
      
    end
    
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
