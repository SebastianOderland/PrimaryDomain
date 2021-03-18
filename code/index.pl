#!/usr/local/cpanel/3rdparty/bin/perl
BEGIN {
    unshift @INC, '/usr/local/cpanel';
}

use Cpanel::LiveAPI ();
use Data::Dumper    ();
use Cpanel::Wrap    ();

sub do_MyExample_stuff {
    my $thing_to_do         = shift;
    my $string_to_mess_with = shift;

    my $result = Cpanel::Wrap::send_cpwrapd_request(
        'namespace' => 'UpdatePrimaryDomain',
        'module'    => 'UpdatePrimaryDomain',
        'function'  => $thing_to_do,
        'data'      => $string_to_mess_with
    );

    if ( $result->{'error'} ) {
        return "Error code $result->{'exit_code'} returned: $result->{'data'}";
    }
    elsif ( ref( $result->{'data'} ) ) {
        return Data::Dumper::Dumper( $result->{'data'} );
    }
    elsif ( defined( $result->{'data'} ) ) {
        return $result->{'data'};
    }
    return 'cpwrapd request failed: ' . $result->{'statusmsg'};
}

my $cpanel = Cpanel::LiveAPI->new();

print "Content-type: text/html\r\n\r\n";

print "<pre>";

print "ECHO test:\n" . do_MyExample_stuff( "ECHO", "Hello, World!" ) . "\n\n";
print "MIRROR test:\n" . do_MyExample_stuff( "MIRROR", "Hello, World!" ) . "\n\n";
print "BOUNCY test:\n" . do_MyExample_stuff( "BOUNCY", "Hello, World!" ) . "\n\n";
print "HASHIFY test:\n" . do_MyExample_stuff( "HASHIFY", "Hello, World!" ) . "\n\n";
print "WRONG test:\n" . do_MyExample_stuff( "WRONG", "Hello, World!" ) . "\n\n";

print "test complete!\n";
$cpanel->end();

