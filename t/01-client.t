#!perl
use strict;
use warnings;

use Test::More;
use Test::Mock::LWP::Dispatch;
use Test::NoWarnings;



my %expected_result = (
	'facebook' => {
		authorize_url => [
                                 'https://graph.facebook.com/oauth/authorize?',
                                 'redirect_uri=http%3A%2F%2Fcpan.org%2Fgot%2Ffacebook',
                                 'client_id=',
                                 'type=web_server'],
		access_token_url => [
                                 'https://graph.facebook.com/oauth/access_token',
                                 'redirect_uri=http%3A%2F%2Fcpan.org%2Fgot%2Ffacebook',
                                 'client_id=',
                                 'client_secret=',
                                 'type=web_server',
                                 'code='],
	},
	'37signals' => {
		authorize_url => [
                                 'https://launchpad.37signals.com/authorization/new',
                                 'redirect_uri=http%3A%2F%2Fcpan.org%2Fgot%2F37signals',
                                 'client_id=',
                                 'type=web_server'],
		access_token_url => [
                                 'https://launchpad.37signals.com/authorization/token',
                                 'redirect_uri=http%3A%2F%2Fcpan.org%2Fgot%2F37signals',
                                 'client_id=',
                                 'client_secret=',
                                 'type=web_server',
                                 'code='],
	},
      'mixi' => {
              authorize_url => [
                                'https://mixi.jp/connect_authorize.pl',
                                'redirect_uri=http%3A%2F%2Fcpan.org%2Fgot%2Fmixi',
                                'client_id=',
                                'type=web_server'],
              access_token_url => [
                                'https://secure.mixi-platform.com/2/token',
                                'redirect_uri=http%3A%2F%2Fcpan.org%2Fgot%2Fmixi',
                                'client_secret=',
                                'client_id=',
                                'type=web_server',
                                'code='],
      },
);
my %params = (
	'facebook' => ['scope' => 'read-write'],
        '37signals' => [],
'mixi' => ['scope' => 'r_profile'],
);


my @sites = keys %expected_result;
my $tests = 1; # no warnings;
foreach my $site_id (@sites) {
    $tests += @{ $expected_result{$site_id}{authorize_url} } + @{ $expected_result{$site_id}{access_token_url} } + 4;
}
plan tests => $tests; 

$mock_ua->map(qr{.*}, sub {
       my $request = shift;
# https://graph.facebook.com/oauth/access_token....
# die $request->uri;
       my $response = HTTP::Response->new(200, 'OK');
       my $content = $request->content;
       if (defined $content and (
                $content =~ /grant_type=authorization_code/
                        and $content =~ /\bcode=/
                or
                $content =~ /grant_type=password/
                        and $content =~ /password=/
                        and $content =~ /username=/
        )) {
         $response->add_content('access_token=abcd&token_type=bearer');
       }
       return $response;
});


use Net::OAuth2::Client;
use Net::OAuth2::Profile::Password;

use Data::Dumper qw(Dumper);
use YAML qw(LoadFile);
my $config = LoadFile('demo/config.yml');

#diag Dumper $config;
foreach my $site_id (@sites) {
	my $authorize_url = web_server_client($site_id)->authorize_url;
        foreach my $exp (@{ $expected_result{$site_id}{authorize_url} }) {
            like ($authorize_url, qr{$exp}, "authorize_url ($exp) of $site_id");
        }
	my $access_token_url = web_server_client($site_id)->access_token_url;
        foreach my $exp (@{ $expected_result{$site_id}{access_token_url} }) {
            like ($access_token_url, qr{$exp}, "access_token_url ($exp) of $site_id");
        }
	my $code = "abcd";
	my $access_token =  web_server_client($site_id)->get_access_token($code, @{$params{$site_id}});
	isa_ok($access_token, 'Net::OAuth2::AccessToken');

	my $username = my $password = "abcd";
	$access_token =  password_client($site_id)->get_access_token( username => $username, password => $password, @{$params{$site_id}});
	isa_ok($access_token, 'Net::OAuth2::AccessToken');

#	diag $access_token->to_string;
        my $response = $access_token->get($config->{sites}{$site_id}{protected_resource_path});
	ok($response->is_success, 'success');

        $response = $access_token->get('/path?field=value');
	ok($response->is_success, 'success');
}

sub client {
	my $site_id = shift;
	Net::OAuth2::Client->new(
		$config->{sites}{$site_id}{client_id},
		$config->{sites}{$site_id}{client_secret},
		site => $config->{sites}{$site_id}{site},
		authorize_path => $config->{sites}{$site_id}{authorize_path},
		access_token_path => $config->{sites}{$site_id}{access_token_path},
		access_token_method => $config->{sites}{$site_id}{access_token_method},
              authorize_url => $config->{sites}{$site_id}{authorize_url},
              access_token_url => $config->{sites}{$site_id}{access_token_url},
	);
}

sub web_server_client {
	my $site_id = shift;
	client( $site_id )->web_server(redirect_uri => ("http://cpan.org/got/$site_id"));
}

sub password_client {
	my $site_id = shift;
	Net::OAuth2::Profile::Password->new( client => client( $site_id ) );
}


