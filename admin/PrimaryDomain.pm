package Cpanel::Admin::Modules::PrimaryDomain::PrimaryDomain;

use strict;
use warnings;
use Data::Dumper;
use Sys::Hostname;
use experimental "switch";
use feature qw/switch/;

use parent 'Cpanel::Admin::Base';
use cPanel::PublicAPI;

# ---
# WHMCS
use HTTP::Request;
use LWP::UserAgent;
# ---


# Initialize PublicAPI
my $public_api = cPanel::PublicAPI->new("host" => hostname);

# Functions accessible through UAPI
use constant _actions =>
(
    'AdminTestFunction',
    'AdminChangePrimaryDomain',
    'AdminGetDNSZone',
    'AdminGetSubDomains',
    'AdminAddDNSRecord',
    'AdminEditDNSRecord',
    'AdminRemoveDNSRecord',
    'AdminResetDNSZone',
    'AdminUpdateWHMCSDomainName',
);

sub AdminTestFunction {
    my ($self, $args) = @_;

    my @output;

    push (@output, {'1' => Dumper($self->{'caller'})});
    push (@output, {'2' => " ----------------------- "});
    push (@output, {'3' => Dumper($self->{'caller'}->{'_cpuser_data'})});
    push (@output, {'4' => " ----------------------- "});
    push (@output, {'5' => Dumper($self->{'caller'}->{'_cpuser_data'}->{'USER'})});

    return \@output;
}

sub AdminChangePrimaryDomain {
    my ($self, $args) = @_;

    my $output = $public_api->whm_api('modifyacct',
    { 
        'user' => $self->{'caller'}->{'_cpuser_data'}->{'USER'},
        'DNS' => $args->{'new_domain'}
    });

    return $output;
}

sub AdminGetSubDomains {
    my ($self, $args) = @_;

    my $subdomains = $public_api->cpanel_api2_request('whostmgr',
    {
        'module' => 'SubDomain',
        'func' => 'listsubdomains',
        'user' => $self->{'caller'}->{'_cpuser_data'}->{'USER'}
    });

    return $subdomains;
}

sub AdminGetDNSZone {
    my ($self, $args) = @_;

    my $domain = $args->{'domain'};

    my @dns_zone = $public_api->whm_api('dumpzone', { 'domain' => $domain });
    my @new_dns_zone = $dns_zone[0]->{'data'}->{'zone'}[0]->{'record'};

    return @new_dns_zone;
}

sub AdminRemoveDNSRecord {
    my ($self, $args) = @_;

    my $domain = $args->{'domain'};
    my $line = $args->{'line'};

    my $output = $public_api->whm_api('getzonerecord', { 'domain' => $domain, "line" => $line });
    my $record_type = $output->{'data'}->{'record'}[0]->{'type'};
    if ($record_type eq "A" || $record_type eq "CNAME" || $record_type eq "MX" || $record_type eq "TXT") {
        my $output2 = $public_api->whm_api('removezonerecord', { 'zone' => $domain, "line" => $line });
        return $output2;
    }

    return $record_type;
}

sub AdminAddDNSRecord {
    my ($self, $args) = @_;

    my $domain = $args->{'domain'};
    my $dns_record = $args->{'dns_record'};
    my $edit_dns_record_output;

    given($dns_record->{'type'}) {
        when ("A") {
            $edit_dns_record_output = $public_api->whm_api('addzonerecord',
            {
                "domain" => $domain,
                "name" => $dns_record->{'name'},
                "class" => "IN",
                "ttl" => $dns_record->{'ttl'},
                "type" => $dns_record->{'type'},
                "address" => $dns_record->{'address'},
            });
        }
        when ("CNAME") {
            $edit_dns_record_output = $public_api->whm_api('addzonerecord',
            {
                'domain' => $domain,
                "name" => $dns_record->{'name'},
                "class" => "IN",
                "ttl" => $dns_record->{'ttl'},
                "type" => $dns_record->{'type'},
                "cname" => $dns_record->{'cname'},
            });
        }
        when ("MX") {
            $edit_dns_record_output = $public_api->whm_api('addzonerecord',
            {
                'domain' => $domain,
                "name" => $dns_record->{'name'},
                "class" => "IN",
                "ttl" => $dns_record->{'ttl'},
                "type" => $dns_record->{'type'},
                "preference" => $dns_record->{'preference'},
                "exchange" => $dns_record->{'exchange'},
            });
        }
        when ("TXT") {
            $edit_dns_record_output = $public_api->whm_api('addzonerecord',
            {
                'domain' => $domain,
                "name" => $dns_record->{'name'},
                "class" => "IN",
                "ttl" => $dns_record->{'ttl'},
                "type" => $dns_record->{'type'},
                "txtdata" => $dns_record->{'txtdata'},
            });
        }
    }

    return $edit_dns_record_output;
}

sub AdminEditDNSRecord {
    my ($self, $args) = @_;

    my $domain = $args->{domain};
    my $line = $args->{line};
    my $dns_record = $args->{dns_record};
    my $edit_dns_record_output;

    given($dns_record->{type}) {
        when ("A") {
            $edit_dns_record_output = $public_api->whm_api('editzonerecord',
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
            $edit_dns_record_output = $public_api->whm_api('editzonerecord',
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
            $edit_dns_record_output = $public_api->whm_api('editzonerecord',
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
            $edit_dns_record_output = $public_api->whm_api('editzonerecord',
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

sub AdminResetDNSZone {
    my ($self, $args) = @_;

    my $domain = $args->{'domain'};

    my $output = $public_api->whm_api('resetzone', { 'domain' => $domain });

    return $output;
}

# WHMCS
sub AdminUpdateWHMCSDomainName {
    my ($self, $args) = @_;

    my $user = $args->{'user'};
    my $old_domain = $args->{'old_domain'};
    my $new_domain = $args->{'new_domain'};

    my $url = 'https://www.oderland.se/clients/includes/api.php';
    #my $ua = LWP::UserAgent->new;

    #$class, $method, $uri, $header, $content

    #my $request = HTTP::Request->new(GET => 'http://www.example.com/');

    #my $search_request = HTTP::Request->new('POST', $url, {
    #    'Content-Type' => 'application/x-www-form-urlencoded'
    #}
    #{
    #    'action' => 'GetClientsProducts',
    #    'username' => 'IDENTIFIER_OR_ADMIN_USERNAME',
    #    'password' => 'SECRET_OR_HASHED_PASSWORD',
    #    'domain' => $old_domain,
    #    'username2' => $user,
    #    'responsetype' => 'json',
    #});

    #my $update_domain_request = HTTP::Request->new('POST', $url, {
    #    'action' => 'UpdateClientProduct',
    #    'username' => 'IDENTIFIER_OR_ADMIN_USERNAME',
    #    'password' => 'SECRET_OR_HASHED_PASSWORD',
    #    'serviceid' => '1',
    #    'domain' => $new_domain,
    #    'responsetype' => 'json',
    #});

    #my $response = $ua->request($search_request);
    #my $response_object = decode_json $response;
    #return $response;
    #if ($resp)

    #my $response = $ua->request($update_domain_request);
}

1;