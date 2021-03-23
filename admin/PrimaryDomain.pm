package Cpanel::Admin::Modules::PrimaryDomain::PrimaryDomain;

use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;
use JSON;

use parent 'Cpanel::Admin::Base';
use Whostmgr::API::1::DNS ();
use cPanel::PublicAPI;


my $cp = cPanel::PublicAPI->new("host" => "cpanel-dev-cl7.oderland.com");

use constant _actions => (
    'AdminChangePrimaryDomain',
    'AdminGetDNSZones',
);

sub AdminChangePrimaryDomain {
    my $class = shift;

    my $self = {
        _args => shift,
    };

    my $user = $self->{_args}{user};
    my $new_primary_domain = $self->{_args}{new_primary_domain};

    my $command = "whmapi1 modifyacct user=" . $user . " DNS=" . $new_primary_domain;

    my $output = `$command`;
    return $output;
}

sub AdminGetDNSZones {
    my $class = shift;

    my $self = {
        _args => shift,
    };

    my $user = $self->{_args}{user};
    my $old_primary_domain = $self->{_args}{old_primary_domain};
    my $new_primary_domain = $self->{_args}{new_primary_domain};

    #my $old_primary_domain_zone_output = $cp->cpanel_api2_request('whostmgr',
    #{
    #    'module' => 'DNS',
    #    'func' => 'dumpzone',
    #    'user' => $user,
    #});

    my $old_primary_domain_zone_output = $cp->whm_api('dumpzone', { 'domain' => $old_primary_domain });
    my $new_primary_domain_zone_output = $cp->whm_api('dumpzone', { 'domain' => $new_primary_domain });


    #my $old_primary_domain_zone_output = Whostmgr::API::1::DNS::dumpzone({"domain" => $old_primary_domain}, "domain");
    #my $old_primary_domain_zone_output = Cpanel::AdminBin::Call::call("Whostmgr", "API", "1", "DNS" {"domain" => $old_primary_domain}, "domain");
    #my $get_old_primary_domain_zone = "whmapi1 dumpzone domain=" . $old_primary_domain;
    #my $old_primary_domain_zone_output = `$get_old_primary_domain_zone`;
    #my $old_json = parse_json($old_primary_domain_zone_output);

    #my $get_new_primary_domain_zone = "whmapi1 dumpzone domain=" . $new_primary_domain;
    #my %new_primary_domain_zone_output = `$get_new_primary_domain_zone`;
    return ($old_primary_domain_zone_output, $new_primary_domain_zone_output);
}

1;