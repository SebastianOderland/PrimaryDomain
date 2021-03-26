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
use experimental "switch";

use feature qw/switch/;

my $cp = cPanel::PublicAPI->new("host" => "cpanel-dev-cl7.oderland.com");

use constant _actions => (
    'AdminChangePrimaryDomain',
    'AdminGetDNSZones',
    'AdminGetSubDomains',
    'AdminAddDNSRecord',
    'AdminEditDNSRecord',
    'AdminRemoveDNSRecord',
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

sub AdminRemoveDNSRecord {
    my $class = shift;

    my $self = {
        _args => shift,
    };

    my $user = $self->{_args}{user};
    my $domain = $self->{_args}{domain};
    my $line = $self->{_args}{line};

    my $output = $cp->whm_api('getzonerecord', { 'domain' => $domain, "line" => $line });
    my $record_type = $output->{data}->{record}[0]->{type};
    if ($record_type eq "A" || $record_type eq "CNAME" || $record_type eq "MX" || $record_type eq "TXT") {
        my $output2 = $cp->whm_api('removezonerecord', { 'zone' => $domain, "line" => $line });
    }

    return $output;
}

sub AdminAddDNSRecord {
    my $class = shift;

    my $self = {
        _args => shift,
    };

    my $user = $self->{_args}{user};
    my $domain = $self->{_args}{domain};
    my $dns_record = $self->{_args}{dns_record};
    my $edit_dns_record_output;

    given($dns_record->{type}) {
        when ("A") {
            $edit_dns_record_output = $cp->whm_api('addzonerecord',
            {
                "domain" => $domain,
                "name" => $dns_record->{name},
                "class" => "IN",
                "ttl" => $dns_record->{ttl},
                "type" => $dns_record->{type},
                "address" => $dns_record->{address},
            });
        }
        when ("CNAME") {
            $edit_dns_record_output = $cp->whm_api('addzonerecord',
            {
                'domain' => $domain,
                "name" => $dns_record->{name},
                "class" => "IN",
                "ttl" => $dns_record->{ttl},
                "type" => $dns_record->{type},
                "cname" => $dns_record->{cname},
            });
        }
        when ("MX") {
            $edit_dns_record_output = $cp->whm_api('addzonerecord',
            {
                'domain' => $domain,
                "name" => $dns_record->{name},
                "class" => "IN",
                "ttl" => $dns_record->{ttl},
                "type" => $dns_record->{type},
                "preference" => $dns_record->{preference},
                "exchange" => $dns_record->{exchange},
            });
        }
        when ("TXT") {
            $edit_dns_record_output = $cp->whm_api('addzonerecord',
            {
                'domain' => $domain,
                "name" => $dns_record->{name},
                "class" => "IN",
                "ttl" => $dns_record->{ttl},
                "type" => $dns_record->{type},
                "txtdata" => $dns_record->{txtdata},
            });
        }
    }

    return $edit_dns_record_output;
}

sub AdminEditDNSRecord {
    my $class = shift;

    my $self = {
        _args => shift,
    };

    my $user = $self->{_args}{user};
    my $domain = $self->{_args}{domain};
    my $line = $self->{_args}{line};
    my $dns_record = $self->{_args}{dns_record};
    my $edit_dns_record_output;

    given($dns_record->{type}) {
        when ("A") {
            $edit_dns_record_output = $cp->whm_api('editzonerecord',
            {
                'domain' => $domain,
                "line" => $line,
                "name" => $dns_record->{name},
                "ttl" => $dns_record->{ttl},
                "type" => $dns_record->{type},
                "address" => $dns_record->{address},
            });
        }
        when ("CNAME") {
            $edit_dns_record_output = $cp->whm_api('editzonerecord',
            {
                'domain' => $domain,
                "line" => $line,
                "name" => $dns_record->{name},
                "ttl" => $dns_record->{ttl},
                "type" => $dns_record->{type},
                "cname" => $dns_record->{cname},
            });
        }
        when ("MX") {
            $edit_dns_record_output = $cp->whm_api('editzonerecord',
            {
                'domain' => $domain,
                "line" => $line,
                "name" => $dns_record->{name},
                "ttl" => $dns_record->{ttl},
                "type" => $dns_record->{type},
                "preference" => $dns_record->{preference},
                "exchange" => $dns_record->{exchange},
            });
        }
        when ("TXT") {
            $edit_dns_record_output = $cp->whm_api('editzonerecord',
            {
                'domain' => $domain,
                "line" => $line,
                "name" => $dns_record->{name},
                "ttl" => $dns_record->{ttl},
                "type" => $dns_record->{type},
                "txtdata" => $dns_record->{txtdata},
            });
        }
    }

    return $edit_dns_record_output;
}

1;