package Net::OAuth2::Profile::Password;

use warnings;
use strict;
use base qw(Net::OAuth2::Profile::Base);
use Net::OAuth2::AccessToken;
use HTTP::Request::Common;
require Net::OAuth2::CommonUtils;

sub get_access_token {
  my $self = shift;
  my %req_params = @_;

  my $request;
  if ($self->client->access_token_method eq 'POST') {
    $request = POST($self->client->access_token_url(), {$self->access_token_params( %req_params)});
  } else {
    $request = HTTP::Request->new(
      $self->client->access_token_method => $self->client->access_token_url($self->access_token_params( %req_params))
  );
  }
  my $response = $self->client->request($request);
  die "Fetch of access token failed: " . $response->status_line . ": " . $response->decoded_content unless $response->is_success;
  my $res_params = Net::OAuth2::CommonUtils->parse_json($response->decoded_content);
  $res_params = Net::OAuth2::CommonUtils->parse_query_string($response->decoded_content) unless defined $res_params;
  die "Unable to parse access token response '".substr($response->decoded_content, 0, 64)."'" unless defined $res_params;
  $res_params->{client} = $self->client;
  return Net::OAuth2::AccessToken->new(%$res_params);
}

sub access_token_params {
  my $self = shift;
  my %options = $self->SUPER::access_token_params(undef, @_);
  $options{grant_type} = 'password';
  return %options;
}

1;