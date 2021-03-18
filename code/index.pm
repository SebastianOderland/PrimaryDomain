#!/usr/local/cpanel/3rdparty/bin/perl
BEGIN {
    unshift @INC, '/usr/local/cpanel';
}

use Cpanel::AdminBin::Call;
 
# $result will be “hello”:
my $result = Cpanel::AdminBin::Call::call('UpdatePrimaryDomain', 'UpdatePrimaryDomain', 'SAY_HI');
print "ECHO test:\n" . $results . "\n\n";
 

# @results will contain the 3 values that GET_INFO() returns.
# $results[0] will be ['foo', 'bar'].
my @results = Cpanel::AdminBin::Call::call('UpdatePrimaryDomain', 'UpdatePrimaryDomain', 'GET_INFO', 'foo', 'bar');
print "ECHO test:\n" . @results . "\n\n";