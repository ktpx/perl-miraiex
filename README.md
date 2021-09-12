# Perl MiraiEx (Firi) Crypto Trading API Package
 
MiraIex (soon to be renamed Firi) is a Norwegian Crypto Exchange  

API Documentation: https://developers.miraiex.com/#/README  
API: https://api.miraiex.com   
URL: https://www.miraiex.com  


Examples:
```
my $api = Miraiex::API->new( apikey => <api_access_key>);
```
```
my $result = $api->market_trade_history( market => $market,
                                          count => $count );
                                            
my $result = get_balances();
```

All calls returns a reference to an array of hashes. See the [API](https://developers.miraiex.com/#/README) documentation for 
more detail.

### Requires

* LWP::UserAgent
* JSON::XS
* URI
* Switch
* Scalar::Util
* Config::General
* Digest::SHA
* Time::HiRes
* URI::Query


If you would like to sign up with the Miriex Exchange, you're welcome to use my
affiliate link below.  

https://miraiex.com/affiliate/?referral=2051eafd  

Tip Jar (for coffee or tea)
```
BTC: bc1q4n6ny3qea3lg687n5dr92a607q4gxfvct4tl2v
ETH: 0xA54cFB231Bf07dA327Deeba9c6fff04CE78dA571
```
Licence: GPLv3

