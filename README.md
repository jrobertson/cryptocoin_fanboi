# Use the cryptocoin_fanboi gen to keep up to date with the latest on crypto currencies


    require 'cryptocoin_fanboi'

    ccf = CryptocoinFanboi.new
    puts ccf.to_s limit: 7

Output:

<pre>
--------------------------------------------------------------
| Name          | USD       | BTC         |  % 24hr| % 1 week|
--------------------------------------------------------------
| Bitcoin       | 13394.7   | 1.0         |   -3.57|    -5.03|
| Ripple        | 2.21889   | 0.00016706  |   -1.21|   113.82|
| Ethereum      | 764.084   | 0.0575287   |    2.19|     0.04|
| Bitcoin Cash  | 2436.01   | 0.18341     |    -4.9|   -18.72|
| Cardano       | 0.689258  | 0.00005189  |    -5.5|    67.22|
| Litecoin      | 228.231   | 0.0171838   |   -0.84|   -17.57|
| IOTA          | 3.55108   | 0.00026736  |   -0.77|    -2.48|
--------------------------------------------------------------
</pre>

Coins data is fetched from coinmarketcap.com using the coinmarketcap gem which is called from the cryptocoin_fanboi gem.


## Resources

* cryptocoin_fanboi https://rubygems.org/gems/cryptocoin_fanboi

cryptocoin_fanboi bitcoin cryptocurrency coinmarketcap gem
