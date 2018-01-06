#!/usr/bin/env ruby

# file: cryptocoin_fanboi.rb


require 'psych'
require 'colored'
require 'coinmarketcap'
require 'table-formatter'
require 'rxfhelper'


=begin

# Examples

## Basic usage

    c = CryptocoinFanboi.new
    
    puts.to_s limit: 5 # Display the top 5 coins
    puts c.this_week   # Display the top 5 coins this week
    puts c.last_day    # Display the top 5 coins in the last 24 hours
    puts c.last_hour   # Display the top 5 coins in the last hour


## Advance usage

### Display a selection of coins in order of rank

    c = CryptocoinFanboi.new watch: %w(btc xrp eth trx dash xmr neo xem)
    puts.to_s

### Ignore possibly risky coins (e.g. Asian stock market coins etc.)

    c = CryptocoinFanboi.new ignore: %w(xp bts kcs gxs rhoc)
    puts c.this_week

=end

class CryptocoinFanboi
  
  attr_reader :coins, :all_coins
  attr_accessor :colored

  def initialize(watch: [], ignore: [], 
                 colored: true, debug: false)

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
  
  def coins()
    @coins.map {|x| OpenStruct.new(x) }
  end
  
  alias abbreviations coin_abbreviations

  def inspect()
    
    c = @coins.inspect.length > 50 ? @coins.inspect[0..50] + '...' : @coins.inspect
    "#<%s:%s @coins=\"%s\ @all_coins=\"...\">" % [self.class, 
                                                  self.object_id, c]
  end
  
  def find(name)

    coins.find {|coin| coin.name =~ /#{name}/i }    

  end

  # View the coins with the largest gains in the past hour
  #  
  def now(limit: 5, markdown: false)
    
    build_table2 top_coins('1h', limit: limit), markdown: markdown
    
  end    
  
  alias hour now
  alias last_hour now

  # View the coins with the largest gains this week (past 7 days)
  #  
  def this_week(limit: 5, markdown: false)    
    
    coins =  top_coins(limit: limit)
    build_table2 coins, markdown: markdown

  end
  
  alias week this_week
  
  # View the coins with the largest gains today (past 24 hours)
  #
  def today(limit: 5, markdown: false)
    
    build_table2 top_coins('24h', limit: limit), markdown: markdown
    
  end

  alias last_day today
  alias day today

  def to_s(limit: 5, markdown: false)

    coins = fetch_coinlist(limit: limit).map do |coin|

      @fields.map {|x| coin[x] }

    end    

    puts 'coins: ' + coins.inspect if @debug
    
    build_table coins, markdown: markdown

  end

  private
  
  def build_table(a, markdown: markdown, labels: @labels)
        
    coins = a.map do |x|
      @growth.has_key?(x[1]) ? x + [@growth[x[1]].to_s] : x
    end    

    format_table(coins, markdown: markdown, labels: @labels)
  end
  
  def build_table2(a, markdown: markdown, labels: @labels)
    
    format_table(a, markdown: markdown, labels: @labels[0..-2])

  end  
  
  def format_table(source, markdown: markdown, labels: @labels)
    s = TableFormatter.new(source: source, labels: labels, markdown: markdown)\
        .display
    
    return s if @colored == false
    
    a = s.lines
    
    body = a[3..-2].map do |line|
      
      fields = line.split('|')   
      
      a2 = fields[5..-2].map {|x| x[/^ +-/] ? x.red : x.green }
      (fields[0..4] + a2 + ["\n"]).join('|')  

    end
    
    (a[0..2] + body + [a[-1]]).join
  end

  def fetch_coinlist(limit: nil)

    @all_coins = JSON.parse(Coinmarketcap.coins.body)\
        .map {|x| OpenStruct.new x}
    
    if @watch.any? then
      return @all_coins.select {|x| @watch.include? x.symbol }
    elsif @ignore.any?
      a = @all_coins.reject {|x| @ignore.include? x.symbol }
    else
      a = @all_coins    
    end    

    limit ? a.take(limit) : a
    
  end

  # fetch the currency prices from the start of the year 
  #
  def fetch_growth(coins)

    puts 'fetching growth ...' if @debug
    
    coins.inject({}) do |r, coin| 

      day1 = @year + '0101'
      puts 'coin: ' + coin.name.inspect if @debug
      
      begin
        
        a = Coinmarketcap.get_historical_price(coin.name.gsub(/ /,'-'), 
                                               day1, day1)
      rescue
        puts 'warning : ' + coin.name.inspect + ' ' + ($!).inspect
      end

      if a and a.any? then
        
        latest_day, year_start = coin.price_usd.to_f, a[0][:close]
        r.merge({coin.name => (100.0 / (year_start / 
                                        (latest_day - year_start))).round(2)})
      else
        r
      end
      
    end
    
  end
  
  def top_coins(period='7d', limit: 5)
    
    a = @coins.sort_by {|x| -x['percent_change_' + period].to_f}.take(limit)
    a.map {|coin| @fields.map {|key| coin[key] }}
    
  end  

end



if __FILE__ == $0 then

  ccf = CryptocoinFanboi.new
  puts ccf.to_s

end