#!/usr/bin/env ruby

# file: cryptocoin_fanboi.rb


require 'excon'
require 'psych'
require 'colored'
require 'coinmarketcap_lite'
require 'table-formatter'
require 'rxfhelper'
require 'rexle'
require 'kramdown'
require 'justexchangerates'
require 'coinquery'
require 'coin360api21'
require 'remote_dwsregistry'

# 02-May 2021 ----
#
# public methods tested:
#
# * this_day
# * this_hour
# * this_week
# * this_month
# * past_60d
# * past_90d

# note: In order to use this gem you will need at least a 
#       valid "basic plan" Coinmarket API key.

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

module Colour

  def colourise(x)
  
    return x if x.to_s.strip.empty? or @colored == false
    
    s3 = (x.to_s.sub(/[\d\.\-]+/) {|s2| "%.2f" % s2.to_f})
    s = s3.length == x.to_s.length ? s3 : s3.sub(/ /,'')
    
    s[/^ *-/] ? s.red : s.green
  end
  
  alias c colourise 
  
end

class CryptocoinFanboi
  include Colour
  using ColouredText
  
  attr_reader :coins, :all_coins
  attr_accessor :colored

  def initialize(watch: [], ignore: [], colored: true, debug: false, 
                 filepath: '.', exchangerate_key: nil, cmc_apikey: nil)

    @colored, @debug, @filepath = colored, debug, filepath
    @exchangerate_key, @cmc_apikey = exchangerate_key, cmc_apikey
    puts 'before coinquery'
    @cq = CoinQuery.new(dym: false, timeout: 7, debug: debug)
    
    @watch= watch.map(&:upcase)
    @ignore = ignore.map(&:upcase)
        
    
    #@fields = %w(rank name price_usd price_btc percent_change_1h 
    #      percent_change_24h percent_change_7d percent_change_year)    
              
    pct_fields = %w(1h 24h 7d 30d 60d 90d).map {|x| 'percent_change_' + x}
    @fields = %w(price) + pct_fields
          
    @year = Time.now.year          
    #@labels = %w(Rank Name USD BTC) + ['% 1hr:', '% 24hr:', 
    #                                   '% 1 week:', '% ' + @year.to_s + ':']
    @labels = %w(Rank Name USD) + ['% 1hr:', '% 24hr:', 
                                '% 7d:','% 30d:','% 60d:','% 90d:']
    
    puts 'about to fetch coinlist'.info if @debug
    @coins = coins = fetch_coinlist()
    puts 'coinlist fetched'.info if @debug
   
    # The following code is commented out because it's non-essential to 
    # returning the current coin prices. It was intended to show yearly 
    # percentage returns
    
=begin    
    # check for the local cache file containing a record of currency 
    # prices from the start of the year
    
    cache_filename = File.join(@filepath, 'cryptocoin_fanboi.yaml')
    puts 'cache_filename: ' + cache_filename.inspect if @debug
    @historic_prices_file = File.join(@filepath, 'ccf_historic.yaml')
    
    @history_prices = if File.exists? @historic_prices_file then
      Psych.load File.read(@historic_prices_file)
    else
      {}
    end
    
    if File.exists? cache_filename then
      
      #load the file
      h = Psych.load File.read(cache_filename)
      
      if @debug then
        puts 'h.key.first: ' + h.keys.first.inspect 
        puts '@year: ' + @year.inspect
      end
      
      @coin_prices = (h.keys.first == @year) ? h[@year] : \
          fetch_year_start_prices(@all_coins)
      
    else
      
      # fetch the currency prices from the start of the year
      @coin_prices = fetch_year_start_prices(@all_coins)
      File.write cache_filename, {@year => @coin_prices}.to_yaml
      
    end
    
    @growth = fetch_growth(coins, @coin_prices)
    puts '@growth: ' + @growth.inspect if @debug
    
    @coins = add_year_growth coins
=end    
    
  end
  
  # best coin this year so far
  #
  def best_coin(default_list=[])

    list = if default_list.empty? then
      self.coin_names(limit: 5)
    else
      default_list
    end
    
    a2 = list.map {|x| [x, btc_gain(x)]}
    a2.max_by {|x| x[1].last}  
  end
  
  def btc_gain(coin)

    a = prices_this_year(coin)
    r = a.min_by {|x | x[1][:btc_price]}
    [r, btc_price(coin) - r[1][:btc_price]]
    
  end
  
  
  def btc_price(coin='Bitcoin', date=nil)
  
    usd = self.price(coin, date)    
    return usd if coin == 'Bitcoin'
    
    puts 'usd: ' + usd.inspect if @debug
    btc = self.price('bitcoin', date)
    (usd / btc)   
  end
  
  def coin_abbreviations()
    @coins.map {|x| "%s (%s)" % [x['name'], x['symbol']] }
  end
  
  alias abbreviations coin_abbreviations  
  
  def coin_names(limit: 10)
    @coins.take(limit).map {|x| x['name']}
  end
  
  def coin(name)
    self.find(name)
  end
  
  def coins()
    @coins.map {|x| OpenStruct.new(x) }
  end
  
  def date_range(raw_d1, raw_d2)
  
    d1, d2 = [raw_d1, raw_d2].map do |x|
      if x.is_a? Date then
        x
      else
        Chronic.parse(x.gsub('-',' '), :context => :past).to_date
      end
    end
    
    (d1..d2).each do |date|
      yield(self, date.strftime("%d %B %Y"))
    end
    
  end

  def inspect()
    
    c = @coins.inspect.length > 50 ? \
        @coins.inspect[0..50] + '...' : @coins.inspect
    "#<%s:%s @coins=\"%s\ @all_coins=\"...\">" % [self.class, 
                                                  self.object_id, c]
  end
  
  def find(name)
    
    if @debug then
      puts 'inside find: name: ' + name.inspect 
      puts 'coins: ' + @coins.inspect
    end
    
    coins.find {|coin| coin.name =~ /#{name}/i or coin.symbol =~ /#{name}/i} 

  end

  # View the coins with the largest gains in the past hour
  #  
  def now(limit: 5, markdown: false, rank: :top)
    
    build_table sort_coins('1h', limit: limit, rank: rank), markdown: markdown
    
  end    
  
  alias hour now
  alias last_hour now
  
  # returns closing price in dollars
  # e.g.  price('tron', '8th September 2017') #=> 0.001427
  #
  def price(raw_coin, raw_date=nil)
  
    coin = raw_coin.downcase.split.map(&:capitalize).join(' ')
    
    return self.coin(coin).quote['USD']['price'].to_f if raw_date.nil?
    puts 'raw_date: ' + raw_date.inspect if @debug
    
    date = if raw_date.is_a? Date then
      raw_date.strftime("%Y%m%d")
    else
      Chronic.parse(raw_date.gsub('-',' ')).strftime("%d%m%Y")
    end
    puts 'date: ' + date.inspect if @debug
      
    # if date is today then return today's price
    
    if date == Date.today.strftime("%d%m%Y")
      puts 'same day' if @debug
      return self.coin(coin).quote['USD']['price'].to_f      
    end
    
    
    if @history_prices[coin] and @history_prices[coin][date] then
      @history_prices[coin][date]
    else
      begin
        
        if @debug then
          puts 'coin: ' + coin.inspect 
          puts 'date: ' + date.inspect
        end
        
        #a = Coinmarketcap.get_historical_price(coin.gsub(/ /,'-'), date, date)
        #puts 'a: ' + a.inspect if @debug        
        
        #r = a.any? ? a.first[:close] : self.coin(coin).quote['USD']['price'].to_f  
        price = @cq.historical_price coin, date
        r = price ? price.to_f : self.coin(coin).quote['USD']['price'].to_f  
        @history_prices[coin] ||= {}
        @history_prices[coin][date] = r
        File.write @historic_prices_file, @history_prices.to_yaml
        
        return r
        
      rescue
        puts ($!).inspect if @debug
      end
    end
    
  end
  
  def past_60d(limit: 5, markdown: false, rank: :top)    
    
    coins =  sort_coins('60d', limit: limit, rank: rank)
    build_table coins, markdown: markdown
    
  end
  
  def past_90d(limit: 5, markdown: false, rank: :top)    
    
    coins =  sort_coins('90d', limit: limit, rank: rank)
    build_table coins, markdown: markdown
    
  end
    
  
  def prices_this_year(coin)
  
    (Date.parse('1 Jan')..Date.today).map do |date|
      
      [date, btc_price: btc_price(coin,date), usd_price: price(coin,date)]

    end  
  end
  
  # returns an array of the prices of Bitcoin in various currencies
  #
  def rates(coin='Bitcoin', currencies: %w(EUR GBP))
  
    jeg = JustExchangeRates.new(base: 'USD', app_id: @exchangerate_key, 
                                debug: @debug)
    usd = self.price(coin).round(2)
    ([:USD] + currencies.map(&:to_sym)).zip(
      [usd, *currencies.map {|currency| (usd * jeg.rate(currency)).round(2) }]
      ).to_h
    
  end

  # View the coins with the largest gains this week (past 7 days)
  #  
  def this_week(limit: 5, markdown: false, rank: :top)    
    
    coins =  sort_coins('7d', limit: limit, rank: rank)
    build_table coins, markdown: markdown

  end
  
  alias week this_week
  
  # View the coins with the largest gains this week (past 7 days)
  #  
  def this_month(limit: 5, markdown: false, rank: :top)    
    
    puts 'inside this_mponth'.info if @debug
    coins =  sort_coins('30d', limit: limit, rank: rank)
    build_table coins, markdown: markdown

  end
  
  alias month this_month
  
  
  # View the coins with the largest gains this 
  # year (since the start of the year)
  #  
  def this_year(limit: 5, markdown: false, rank: :top)    
    
    build_table sort_coins('year', limit: limit, rank: rank), markdown: markdown

  end
  
  alias year this_year
  
  # View the coins with the largest gains today (past 24 hours)
  #
  def today(limit: 5, markdown: false, rank: :top)
    
    build_table sort_coins('24h', limit: limit, rank: rank), markdown: markdown
    
  end

  alias last_day today
  alias day today
  
  def total_market_cap()

    '$' + Coin360Api21::Global.new.latest.total_market_cap.round.to_s\
        .reverse.gsub(/...(?=.)/,'\&,').reverse

  end
  
  def to_html()
  
    xpath = (5..8).map {|x| 'tbody/tr/td[' + x.to_s + ']' }.join(' | ')
    doc = Rexle.new(Kramdown::Document.new(self.to_s(markdown:true)).to_html)
    doc.root.xpath(xpath).each do |x|
    
      x.attributes['class'] = (x.text[0] == '-' ? 'negative' : 'positive')
    
    end
    
    doc.root.xml
    
  end

  def to_s(limit: 5, markdown: false, rank: :top)

    coins = (fetch_coinlist(limit: limit))  
    
    coins2 = add_year_growth(coins)
    
    puts ('coins2: ' + coins2.inspect).debug if @debg
    
    coins3 = coins2.map do |coin|
      
      puts ('coin: ' + coin.inspect).debug if @debug
      a2 = %w(cmc_rank name).map {|x| coin[x]} 
      puts 'a2: ' + a2.inspect
      a3 = @fields.map {|x| coin['quote']['USD'][x].to_f.round(2) }
      puts 'a3: ' + a3.inspect
      a2 + a3
    end  

    puts ('coins3: ' + coins3.inspect).debug if @debug


    build_table coins3, markdown: markdown

  end

  private

  # adds growth from the start of the year
  #
  def add_year_growth(coins)
    
    coins.each do |x|
      
      puts 'x.name: ' + x.name if @debug
      
      if @growth.has_key?(x.name) then
        x.percent_change_year = @growth[x.name].to_s
      else
        x.percent_change_year = '-'
      end
    end    
    
    coins
    
  end
  
  def build_table(a, markdown: markdown, labels: @labels)
        
    if @debug then
      puts 'inside build_table' 
      puts 'a : ' + a.inspect
      puts '@growth: ' + @growth.inspect
    end
        
    format_table(a, markdown: markdown, labels: @labels)
  end  
  
  def format_table(source, markdown: markdown, labels: @labels)
    
    if @debug then
      puts 'source: ' + source.inspect
      puts 'labels: ' + labels.inspect
    end
    
    s = TableFormatter.new(source: source, labels: labels, divider: '|', 
                           markdown: markdown).display
    
    return s if @colored == false or markdown
    
    a = s.lines
    
    body = a[3..-2].map do |line|
      
      fields = line.split('|')   
      
      a2 = fields[4..-2].map {|x| c(x) }
      puts 'at: ' + a2.inspect if @debug
      (fields[0..3] + a2 + ["\n"]).join('|')  

    end
    
    (a[0..2] + body + [a[-1]]).join
  end

  def fetch_coinlist(limit: nil)

    body = CoinmarketcapLite.new(apikey: @cmc_apikey).coins
    @all_coins = body['data']\
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
  def fetch_year_start_prices(coins)
    
    coins.inject({}) do |r, coin| 

      day1 = '01-01-' + @year.to_s
      puts 'coin: ' + coin.name.inspect if @debug
      
      begin
        
        #a = Coinmarketcap.get_historical_price(coin.name.gsub(/ /,'-'), 
        #                                       day1, day1)
        price = @cq.historical_price coin.symbol, day1
        
      rescue
        puts 'warning : ' + coin.name.inspect + ' ' + ($!).inspect
      end

      if price then
        
        r.merge({coin.name => price.to_f})
      else
        r
      end
      
    end
    
  end

  
  # fetch the currency prices from the start of the year 
  #
  def fetch_growth(coins, coin_prices)

    if @debug then
      puts 'fetching growth ...'
      puts 'coin_prices: ' + coin_prices.inspect
    end
    
    coins.inject({}) do |r, coin| 

      year_start_price = coin_prices[coin.name]
      
      if year_start_price then
        
        latest_day = coin.quote['USD']['price'].to_f
        puts "latest_day: %s  year_start: %s" % \
            [latest_day, year_start_price] if @debug
        r.merge({coin.name => (100.0 / (year_start_price / 
                                   (latest_day - year_start_price))).round(2)})
      else
        r
      end
      
    end
    
  end
  
  def sort_coins(period='7d', limit: 5, rank: :top)
    
    puts 'sorting coins ...'.info if @debug
    puts '@coins[0]: ' + @coins[0].inspect
    
    a = @coins.sort_by {|x| -x.quote['USD']['percent_change_' + period].to_f}
    a.reverse! if rank == :bottom
    a.take(limit).map do |coin|
      [coin.cmc_rank, coin.name] + @fields.map {|key| coin.quote['USD'][key].round(2) }
    end
    
  end  

end

class CryptocoinFanboiPlus < CryptocoinFanboi

  def initialize(regx, watch: [], ignore: [], colored: true, debug: false, 
                 filepath: '.')          

    reg = if regx.is_a? String then
      RemoteDwsRegistry.new domain: regx
    else
      regx
    end
    
    exchangerate_key = JustExchangeRatesPlus.fetch_app_id(reg)
    puts 'exchangerate_key:'  + exchangerate_key.inspect if debug
    
    cmc_apikey = CoinmarketcapLitePlus.fetch_apikey(reg)
    puts 'cmc_apikey: ' + cmc_apikey.inspect if debug

    super(watch: watch, ignore: ignore, colored: colored, debug: debug, 
          filepath: filepath, exchangerate_key: exchangerate_key, 
          cmc_apikey: cmc_apikey)
    
  end
  
end



if __FILE__ == $0 then

  ccf = CryptocoinFanboi.new
  puts ccf.to_s

end
