package Miraiex::API;
##
#
# Perl MiraiEx Crypto Trading API Package
#  
# API: https://api.miraiex.com
# URL: https://www.miraiex.com
# 
# If you would like to sign up with the Miriex Exchange, you're welcome to use my
# affiliate link below.  
#
# Miraiex Affiliate Link: https://miraiex.com/affiliate/?referral=2051eafd
#
# LICENCE: GPLv3
#
# Disclaimer: Trade at your own risk, Crypto is highly volatilee.  Author takes no
#             responsibility from usage of this API. 
# 
#  TODOS:  Signed requests do not work as per the api documentation.
#           
##

our $VERSION = '2021.09.01';

#use 5.032001;
use LWP::UserAgent;
use JSON::XS;
use URI;
use Switch;
use warnings;
use strict;
use Scalar::Util;
use Config::General;
use Digest::SHA qw(hmac_sha256_hex);
use Time::HiRes;
use URI::Query;

my $api_ver	  = "v2";
my $api_url       = "https://api.miraiex.com";
my $http_header   = "miraiex-access-key";
my @trade_markets = ( "ethnok", "xrpnok", "dainok", "btcnok", "ltcnok", "adanok");

# Subs

sub new {

   my ($class, %params) = @_;

   my $ua = LWP::UserAgent->new();
   my $self = { ua => $ua,
                apikey => $params{apikey},
   };
 
   $self->{'secretkey'} = $params{secretkey} if $params{secretkey};
   $self->{'clientid'}  = $params{clientid}  if $params{clientid};

   bless $self, $class;

   return $self;
}

sub _api {
    
    my ($self, $method, $url, $data, $params ) = @_;
    my $result; my $headers; my $signature;

    $method = uc $method;

    if (exists $params->{'signed'}) {

      if ( exists $self->{'secretkey'} && exists $self->{'clientid'} ){
         my $timestamp = time();
         my %body = ( validity  => "2000",
                      timestamp => "$timestamp" );

         my $json = encode_json(\%body);

         print "$json\n";
#         $signature = generate_signature($self->{'secretkey'}, $json);
         $signature = hmac_sha256_hex($json, $self->{'secretkey'});

         $headers = [ 'miraiex-user-clientid'   => "$self->{'clientid'}", 
                      'miraiex-user-access-key' => "$signature" ];
       }
       else {
          $headers = [ 'Content-Type'  => 'application/json; charset=UTF-8', 
                       'miraiex-access-key' => "$self->{'apikey'}" ];
       }
    }

    my $path = "$api_url" . "$url";
    my $request;

    if ($data) {
       $request = HTTP::Request->new( $method => "$path" , $headers, $data );   
    } else {
       $request = HTTP::Request->new( $method => "$path" , $headers );   
    }

    my $response = $self->ua->request($request);

    if ($response->is_success) {
       if ($response->decoded_content) {
          $result = decode_json($response->decoded_content); 
       }
    }
    else {  
       print $response->content;
    }

    return $result;
}


sub get_priv {

    my ($self, $url, $data) = @_;

    return $self->_api('get', $url, $data, { signed => 1 } );
}

sub get_pub {

    my ($self, $url, $data) = @_;

    return $self->_api('get', $url, $data );
}

sub post {

    my ($self, $url, $data) = @_;

    return $self->_api('post', $url, $data, { signed => 1 });
}

sub delete {

    my ($self, $url, $data) = @_;

    return $self->_api('delete', $url, $data, {  signed => 1 });

}

sub ua {
   return $_[0]->{'ua'};
}


sub generate_signature {

   my ( $secret, @data ) = @_;

   my $digest = hmac_sha256_hex(@data, $secret);
   print $digest;
   return $digest;
}

## Get Server Time

sub time {

   my $self = shift;

   my $result = $self->get_pub("/time");

   return $result;
}

## Get market Pairs

sub market {

   my ($self, %params) = @_;

   if (exists $params{'market'}) {
      return $self->get_pub("/v2/markets/$params{'market'}");
   }
   else {
      return $self->get_pub("/v2/markets");
   }
}

## Trade History for specific market
## Params: Count

sub market_trade_history {

   my ($self, %params) = @_;
   my $url; my $count = 100;

   if (exists $params{'market'}) {
      $url = "/v2/markets/$params{'market'}/history";
   }
   else {
     print "No market specified"; return 0;
   }
   if (exists $params{'count'}) {
      $count = $params{'count'};
   }
   return $self->get_pub($url . "?count=$count");

}

## Get Market Tickers
## Params: market 
sub ticker {

   my ($self , %params) = @_;
   my $url; 

   if (exists $params{'market'}) {
     $url = "/v2/markets/$params{'market'}/ticker";
   }  
   else {
     $url = "/v2/markets/tickers";
   }

   my $result = $self->get_pub($url);

   return $result;
}

## Get Account Balances

sub balances {
   return $_[0]->get_priv("/v2/balances");
}

## Get Account addresses

sub deposit_address {
   return $_[0]->get_priv("/v2/deposit/address");
}

## Get Account Deposits

sub deposit_history {
   return $_[0]->get_priv("/v2/deposit/history");
}

## Get all Filled or cancelled orders
## Params: count, market 

sub history_orders {

  my ( $self, %params ) = @_;
  my $count = 100; my $url = "/v2/history/orders";

  if ( exists $params{'market'} ) {
    $ url = $url . "/$params{'market'}";
  }

  if (exists $params{'count'}) {
     $count = $params{'count'};
  }

  return $self->get_priv("$url?count=$count");

}

## Get all trade history (all, year or year-month)
## Params: count, direction

sub history_trades {

   my ($self, %params) = @_;

   my $url = "/v2/history/trades";
   my $query;

   if (exists $params{'month'}) {
      $url = $url . "/" . "$params{'month'}";
   }

   if (exists $params{'year'}) {
      $url = $url . "/" . "$params{'year'}";
   }

   if (exists $params{'direction'} || 
       exists $params{'count'} ) {
      $query = URI::Query->new(%params);
      $url = "$url?" . "$query";
   }      
   
   my $result = $self->get_priv($url);

   return $result;
}


# Get Market Orderbooks 

sub market_depth {

   my ($self, %params) = @_; 
   my $result;

   if (not exists $params{'market'}) {
      print "No market specified.\n";
   } 
   else {
     my $market = $params{'market'};
     $result =  $self->get_pub("/v2/markets/$market/depth");
   }
 
   return $result;
}
   
# Get active orders
# Params: market 

sub active_orders {

   my ($self, %params) = @_;
   my $url = "/v2/orders";

   if (exists $params{'market'}) {
      $url = $url . "/$params{'market'}";
   }

   my $result = $self->get_priv($url);

   return $result;
}

# Get all filled or closed orders

sub orders_history {

   my ($self, %params) = @_;
   my $url = "/v2/orders/history";

   if (exists $params{'market'}) {
      $url =  "/v2/orders/$params{'market'}/history";
   }
   if (exists $params{'count'}) {
      $url = $url . "?count=$params{'count'}";
   }

   my $result = $self->get_priv($url);
 
   return $result;
}

# Create market order

sub create_order {
 
    my ($self, %params) = @_;

    # Sanitize parameters
    my %body = (
         'market' => $params{'market'},
         'type'   => $params{'type'},
         'price'  => $params{'price'},
         'amount' => $params{'amount'}
    );
 
    my $json = encode_json \%body;

    my $result = $self->post("/v2/orders", $json);

    return $result;
}

# Delete order in a market, orderid, or all orders.

sub delete_order {

   my ($self, %params) = @_;
   my $url = "/v2/orders";

   if ( exists $params{'market'}) {
      $url = $url . "/" . $params{'market'};
   }
   elsif ( exists $params{'orderid'} ) {
      $url = $url . "/" . $params{'orderid'};
   }

   my $result = $self->delete($url);

   return $result;
}

# Get all transaction history

sub history_transactions {

   my ($self, %params) = @_;

   my $url = "/v2/history/transactions";
   my $query;

   if (exists $params{'month'}) {
      $url = $url . "/" . "$params{'month'}";
      delete $params{'month'};
   }

   if (exists $params{'year'}) {
      $url = $url . "/" . "$params{'year'}";
      delete $params{'year'};
   }

   if (exists $params{'direction'} || 
       exists $params{'count'} ) {
      $query = URI::Query->new(%params);
      $url = "$url?" . "$query";
   }      
   
   my $result = $self->get_priv($url);

   return $result;
}

1;
