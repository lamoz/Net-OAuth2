#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Net::OAuth2' ) || print "Bail out!
";
    use_ok( 'Net::OAuth2::Profile::Password' ) || print "Bail out!
";
}

diag( "Testing Net::OAuth2 $Net::OAuth2::VERSION, Perl $], $^X" );
