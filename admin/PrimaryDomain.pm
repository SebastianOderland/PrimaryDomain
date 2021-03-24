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
    'AdminGetSubDomains',
);

sub AdminChangePrimaryDomain {
    my $class = shift;

    my $self = {
        _args => shift,
    };

    my $user = $self->{_args}{user};
    my $new_domain = $self->{_args}{new_domain};

    my $command = "whmapi1 modifyacct user=" . $user . " DNS=" . $new_domain;

    my $output = `$command`;
    return $output;
}

sub AdminGetSubDomains {
    my $class = shift;

    my $self = {
        _args => shift,
    };

    my $user = $self->{_args}{user};

    my $subdomains = $cp->cpanel_api2_request('whostmgr',
    {
        'module' => 'SubDomain',
        'func' => 'listsubdomains',
        'user' => $user,
    });

    return $subdomains;
}

sub AdminGetDNSZones {
    my $class = shift;

    my $self = {
        _args => shift,
    };

    my $user = $self->{_args}{user};
    my $old_domain = $self->{_args}{old_domain};
    my $new_domain = $self->{_args}{new_domain};

    my $old_primary_domain_zone_output = $cp->whm_api('dumpzone', { 'domain' => $old_domain });
    my $new_primary_domain_zone_output = $cp->whm_api('dumpzone', { 'domain' => $new_domain });

    return ($old_primary_domain_zone_output, $new_primary_domain_zone_output);
}

1;