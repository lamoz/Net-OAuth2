package Net::OAuth2::CommonUtils;
use warnings;
use strict;

use URI;
use JSON;

sub parse_query_string {
  my $class = shift;
  my $str = shift;
  my $uri = URI->new;
  $uri->query($str);
  return {$uri->query_form};
}

sub parse_json {
  my $class = shift;
  my $str = shift;
  my $obj = eval{local $SIG{__DIE__}; decode_json($str)};
  return $obj;
}

1;