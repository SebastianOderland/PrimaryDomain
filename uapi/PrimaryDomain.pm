package Cpanel::API::PrimaryDomain;

use strict;
use warnings;
use Data::Dumper;
use JSON;
use Sys::Hostname;
use feature qw/switch/;
use List::Util qw(any);

use Cpanel::AdminBin::Call;
use Cpanel::Api2::Exec;
use Whostmgr::API::1::DNS();

# ---
# WHMCS
use HTTP::Request;
use LWP::UserAgent;
# ---

sub plugin_info {
    my ( $args, $result ) = @_;
    my @output;
    local $Data::Dumper::Terse = 1;

    #my $primary_domain = %Cpanel::CPDATA{'DNS'};
    #push (@output, {'primary_domain' => $primary_domain});
    #my $addon_domains = Dumper(Cpanel::API::_execute( 'DomainInfo', 'list_domains')->{'data'}->{'addon_domains'});
    #push (@output, {'addon_domains' => $addon_domains});
 
    my $domains = Cpanel::API::_execute('DomainInfo', 'list_domains')->{'data'};

    push (@output, {'primary_domain' => Dumper($domains->{'main_domain'})});
    push (@output, {'addon_domains' => Dumper($domains->{'addon_domains'})});
    push (@output, {'sub_domains' => Dumper($domains->{'sub_domains'})});
    push (@output, {'alias_domains' => Dumper($domains->{'parked_domains'})});
    push (@output, {'test_function' => Dumper(Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminTestFunction'))});

    $result->data(\@output);
    return 1;
}

sub change_primary_domain {
    my ( $args, $result ) = @_;

    my @output;

    my $old_domain = %Cpanel::CPDATA{DNS};
    my $new_domain = $args->get('new_domain');
    
    push (@output, {'Output: old_domain' => $old_domain});
    push (@output, {'Output: new_domain' => $new_domain});

    my $old_domain_info = Cpanel::API::_execute( 'DomainInfo', 'single_domain_data',
    {
        'domain'    => $old_domain,
    });

    my $new_domain_info = Cpanel::API::_execute( 'DomainInfo', 'single_domain_data',
    {
        'domain'    => $new_domain,
    });

    # "New" Domain exists?
    if($new_domain_info->{'status'} ne 1) {
        $Cpanel::CPERROR{'changeprimarydomain'} = 'The domain [' . $new_domain . '] does not exist on this account!';
        return;
    }
    # "New" Domain is an addon domain?
    if($new_domain_info->{'data'}->{'type'} ne 'addon_domain') {
        $Cpanel::CPERROR{'changeprimarydomain'} = 'The domain [' . $new_domain . '] is not an addon domain!';
        return;
    }
    # New Domain and Current Domain is the same?
    if ($old_domain eq $new_domain) {
        $Cpanel::CPERROR{'changeprimarydomain'} = 'Old and new primary domain are the same!';
        return;
    }
    # Are the documentroots the same?
    if ($old_domain_info->{'data'}->{'documentroot'} ne $new_domain_info->{'data'}->{'documentroot'}) {
        $Cpanel::CPERROR{'changeprimarydomain'} = 'The current Addon Domain and the current Primary Domain needs to have the same Documentroot!';
        return;
    }

    push (@output, {"Output: CPANEL::CPDATA" => \%Cpanel::CPDATA});

    # STORE OLD SUBDOMAINS
    my @old_subdomains = get_subdomains();
    push (@output, {"Output: get_old_subdomains" => \@old_subdomains});

    # STORE OLD DNS ZONES
    my @old_dns_zone_for_old_domain = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZone', { "user" => $Cpanel::user, "domain" => $old_domain});
    my @old_dns_zone_for_new_domain = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZone', { "user" => $Cpanel::user, "domain" => $new_domain});

    # DELETE ALL SUBDOMAINS ON THE ADDON DOMAIN
    my $subdomain_output = delete_subdomains($old_domain, $new_domain, \@old_subdomains);
    my @subdomains_for_old_domain = $subdomain_output->{'subdomains_for_old_domain'};
    my @subdomains_for_new_domain = $subdomain_output->{'subdomains_for_new_domain'};
    push (@output, {"Output: delete_subdomains" => $subdomain_output});

    # DELETE CURRENT ADDON DOMAIN
    push (@output, {"Output: delete_addon_domain" => delete_addon_domain($new_domain)});

    # CHANGE PRIMARY DOMAIN
    push (@output, {"Output: change_primary_domain" => Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminChangePrimaryDomain',{ "user" => $Cpanel::user,"new_domain" => $new_domain })});

    # CREATE NEW ADDON DOMAIN
    push (@output, {"Output: create_addon_domain" => create_addon_domain($old_domain)});

    my @temp_new_subdomains = get_subdomains();
    push (@output, {"Output: get_new_subdomains" => \@temp_new_subdomains});

    # DELETE THE AUTOMATICALLY CREATED SUBDOMAIN
    push (@output, {"Output: delete_subdomains" => delete_subdomains($old_domain, $new_domain, \@temp_new_subdomains)});

    # STORE NEW DNS ZONES
    my @new_dns_zone_for_old_domain = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZone', { "user" => $Cpanel::user, "domain" => $old_domain});
    my @new_dns_zone_for_new_domain = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZone', { "user" => $Cpanel::user, "domain" => $new_domain});

    # STORE NEW SUBDOMAINS
    my @new_subdomains = get_subdomains();
    push (@output, {"Output: get_new_subdomains" => \@new_subdomains});


    # IMPORT OLD DNS RECORDS TO NEW DNS ZONE
    my @fix_old_primary_domain_dns_zone_output = fix_old_primary_domain_dns_zone($old_domain, \@old_subdomains, \@old_dns_zone_for_old_domain, \@new_dns_zone_for_old_domain);
    push (@output, {"Output: fix_old_primary_domain_dns_zone" => \@fix_old_primary_domain_dns_zone_output});

    my @fix_new_primary_domain_dns_zone_output = fix_new_primary_domain_dns_zone($new_domain, \@new_subdomains, \@subdomains_for_new_domain, \@old_dns_zone_for_new_domain, \@new_dns_zone_for_new_domain);
    push (@output, {"Output: fix_new_primary_domain_dns_zone" => \@fix_new_primary_domain_dns_zone_output});

    # RECREATE SUBDOMAINS
    push (@output, {"Output: create_subdomains_for_old_domain" => create_subdomains($old_domain, \@subdomains_for_old_domain, \@old_dns_zone_for_old_domain)});
    push (@output, {"Output: create_subdomains_for_new_domain" => create_subdomains($new_domain, \@subdomains_for_new_domain, \@old_dns_zone_for_new_domain)});

    $result->data(\@output);
    return 1;
}




# "Sub" functions

sub get_subdomains {
    my $subdomains_output = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetSubDomains', { "user" => $Cpanel::user });
    my @subdomains;
    for my $index (@{$subdomains_output->{"cpanelresult"}->{"data"}}) {
        push(@subdomains, {'domainkey' => $index->{'domainkey'}, 'subdomain' => $index->{'subdomain'}, 'domain' => $index->{'domain'}, 'documentroot' => $index->{'basedir'}});
    }
    return @subdomains;
}

sub delete_subdomains {
    my ( $old_domain, $new_domain, $subdomains ) = @_;
    my @subdomains = @{$subdomains};

    my %output;

    my @subdomains_for_old_domain;
    my @subdomains_for_new_domain;
    my @servername_for_all_addon_domains;

    my $addon_domains = Cpanel::API::_execute( 'DomainInfo', 'list_domains')->{'data'}->{'addon_domains'};
    for my $addon_domain (@{$addon_domains}) {
        my $servername = Cpanel::API::_execute( 'DomainInfo', 'single_domain_data',
            {
                'domain'    => $addon_domain,
            })->{'data'}->{'servername'};

        $servername =~ s/[.]\Q$old_domain//;

        push(@servername_for_all_addon_domains, $servername);
    }

    my $index = 0;
    for my $subdomain (@{$subdomains}) {
        $output{'servernames'} = \@servername_for_all_addon_domains;
        
        # NW
        my $code = any { $subdomain->{'subdomain'} eq $_ } @servername_for_all_addon_domains;
        if ($code == 0) { 
            $output{$index} = $code;
            $index = $index + 1;
            if (index ($subdomain->{'domain'}, $new_domain) != -1) {
                my $command = "cpapi2 SubDomain delsubdomain domain=$subdomain->{'domain'}";
                my $command_output = `$command`;
                $output{'result'} = $command_output;
                push (@subdomains_for_new_domain, $subdomain);
            }
            else {
                push (@subdomains_for_old_domain, $subdomain);
            }
        }
        
    }
    $output{'subdomains_for_old_domain'} = \@subdomains_for_old_domain;
    $output{'subdomains_for_new_domain'} = \@subdomains_for_new_domain;

    return \%output;
}

sub create_subdomains {
    my ( $domain, $subdomains, $old_dns_zone ) = @_;
    my @subdomains = @{$subdomains};
    my @old_dns_zone = @{$old_dns_zone};

    my %output;
    
    my @data;
    push(@data, $domain);
    for my $subdomain (@{$subdomains[0]}) { 
        my $command = "cpapi2 SubDomain addsubdomain domain=$subdomain->{'subdomain'} rootdomain=$domain dir=$subdomain->{'documentroot'}";
        my $command_output = `$command`;

        #$output{'result'} = $command_output;
        #push (@data, $subdomain);

        my @new_dns_zone_for_new_domain = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZone', { "user" => $Cpanel::user, "domain" => $domain});

        my @records_to_remove;

        for my $dns_record (@{$new_dns_zone_for_new_domain[0]}) {
            push(@data, $dns_record->{'name'});
            push(@data, $subdomain);
            if (index($dns_record->{'name'}, $subdomain->{'subdomain'}) != -1) {
                push(@records_to_remove, $dns_record->{'Line'});
            }
        }
        
        @records_to_remove = sort { $b <=> $a } @records_to_remove;
        push(@data, \@records_to_remove);
        push(@data, $command_output);
        
        for my $dns_record (@records_to_remove) {
            my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminRemoveDNSRecord',
                {
                    "user" => $Cpanel::user,
                    "domain" => $domain,
                    "line" => $dns_record,
                });

            #push (@output, $result);
        }

        for my $dns_record (@{$old_dns_zone[0]}) {
            if (index($dns_record->{'name'}, $subdomain->{'subdomain'}) != -1) {
                my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminAddDNSRecord',
                    {
                    "user" => $Cpanel::user,
                    "domain" => $domain,
                    "dns_record" => $dns_record,
                });

                #push (@output, $result);
            }
        }
    }
    $output{'data'} = \@data;

    return \%output;
}

sub delete_addon_domain {
    my ( $domain ) = @_;
    my %output;
    my $primary_domain = %Cpanel::CPDATA{DNS};

    my $domain_info = Cpanel::API::_execute( 'DomainInfo', 'single_domain_data',
    {
        'domain'    => $domain,
    })->{'data'};

    my $servername = $domain_info->{'servername'};
    $servername =~ s/.$primary_domain/_$primary_domain/g;

    if ($domain_info->{'type'} eq 'addon_domain')
    {
        my $command = "cpapi2 AddonDomain deladdondomain domain=$domain subdomain=$servername";
        my $command_output = `$command`;
        
        #$output{'status' => $command_output->{'status'}};
        $output{'status'} = 1;
        $output{'result'} = $command_output;
    }
    else
    {
        $Cpanel::CPERROR{'changeprimarydomain'} = "[$domain] is not an Addon Domain!";
        $output{'status' => 0};
        $output{'result'} = "[$domain] is not an Addon Domain!";
    }
    return \%output;
}

sub create_addon_domain {
    my ($domain) = @_;
    my $output;

    my $subdomain = $domain;
    $subdomain =~ s/\..*//;

    my $command = "cpapi2 AddonDomain addaddondomain dir=public_html newdomain=$domain subdomain=$subdomain";
    $output = `$command`;
}

sub fix_old_primary_domain_dns_zone {
    my ($domain, $subdomains, $old_dns_zone, $new_dns_zone) = @_;

    my @output;
    my @subdomains = @{$subdomains};

    my @old_dns_zone = @{$old_dns_zone};
    my @new_dns_zone = @{$new_dns_zone};

    my @records_to_exclude = ();

    # CHECK IF SUBDOMAIN IS A "STANDARD" SUBDOMAIN, OR AN ADDED/CUSTOM SUBDOMAIN
    # ONLY KEEP ADDED/CUSTOM SUBDOMAINS IN THE LOOP BELOW

    for my $old_dns_record (@{$old_dns_zone[0]}) {
        for my $subdomain (@{$subdomains}) {
            if (index($old_dns_record->{'name'}, $subdomain->{'subdomain'}) != -1) {
                push (@output, $old_dns_record->{'name'});
                push (@output, $subdomain);
                push (@records_to_exclude, $old_dns_record->{'Line'});
                last;
            }
        }
    }

    my @records_to_remove;

    for my $new_dns_record (@{$new_dns_zone[0]}) {
        push (@records_to_remove, $new_dns_record->{'Line'});
    }

    my @records_to_remove = sort { $b <=> $a } @records_to_remove;

    # REMOVE ALL DNS RECORD FROM CURRENT ZONE
    for my $line_number (@records_to_remove) {
        my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminRemoveDNSRecord',
        {
            "user" => $Cpanel::user,
            "domain" => $domain,
            "line" => $line_number,
        });

        push (@output, $result);
    }

    # ADD BACK OLD DNS RECORD - SUBDOMAIN RECORDS
    for my $dns_record (@{$old_dns_zone[0]}) {
        if ( grep( /^$dns_record->{Line}$/, @records_to_exclude ) ) {
            push (@output, "!");
        }
        else {
            my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminAddDNSRecord',
            {
                "user" => $Cpanel::user,
                "domain" => $domain,
                "dns_record" => $dns_record,
            });

            push (@output, $result);
        }
    }

    return @output;
}

sub fix_new_primary_domain_dns_zone {
    my ($domain, $subdomains, $subdomains_for_this_addon_domain, $old_dns_zone, $new_dns_zone) = @_;
    # REMOVE ALL DNS RECORDS
    # ADD OLD DNS RECORDS BACK
    # ADD RECORDS BACK FROM THE NEW DNS ZONE THAT WE WANT TO KEEP
    my @service_subdomains = ('cpanel', 'cpcalendars', 'webmail', 'whm', 'cpcontacts', 'webdisk');

    my @output;
    my @subdomains = @{$subdomains};
    my @subdomains_for_this_addon_domain = @{$subdomains_for_this_addon_domain};
    my @old_dns_zone = @{$old_dns_zone};
    my @new_dns_zone = @{$new_dns_zone};

    my @records_to_remove = ();
    my @records_to_keep = ();

    # CHECK IF SUBDOMAIN IS A "STANDARD" SUBDOMAIN, OR AN ADDED/CUSTOM SUBDOMAIN
    # ONLY KEEP "STANDARD" SUBDOMAINS IN THE LOOP BELOW

    # GET ALL ADDON DOMAINS
    # GET THE SUBDOMAIN FOR THE ADDON DOMAINS

    my @servername_for_all_addon_domains;

    my $addon_domains = Cpanel::API::_execute( 'DomainInfo', 'list_domains')->{'data'}->{'addon_domains'};
    for my $addon_domain (@{$addon_domains}) {
        my $servername = Cpanel::API::_execute( 'DomainInfo', 'single_domain_data',
            {
                'domain'    => $addon_domain,
            })->{'data'}->{'servername'};

        $servername =~ s/[.]\Q$domain//;

        push(@servername_for_all_addon_domains, $servername);
    }
    push (@output, \@servername_for_all_addon_domains);

    push (@output, \@subdomains_for_this_addon_domain);

    for my $new_dns_record (@{$new_dns_zone[0]}) {
        push (@records_to_remove, $new_dns_record->{'Line'});
        my $temp_subdomain = $new_dns_record->{'name'};
        $temp_subdomain =~ s/[.].*//;

        if ($new_dns_record->{'type'} eq 'A' || $new_dns_record->{'type'} eq 'AAAA') {
            for my $subdomain (@{$subdomains}) {
                if ( grep(!/^$subdomain$/, @servername_for_all_addon_domains ) ) {
                    # If the record name contains a subdomain, don't delete it.
                    if (index($new_dns_record->{'name'}, $subdomain->{'subdomain'}) != -1) {
                        if (($temp_subdomain ~~ @service_subdomains) == 0) {
                            push (@records_to_keep, $new_dns_record);
                        }
                        last;
                    }
                }
            }
        }
    }


    # Sorts the array in reverse, so it deletes the last record first.
    # If we don't, the line numbers will be incorrect.
    @records_to_remove = sort { $b <=> $a } @records_to_remove;

    for my $line_number (@records_to_remove) {
        my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminRemoveDNSRecord',
        {
            "user" => $Cpanel::user,
            "domain" => $domain,
            "line" => $line_number,
        });

        #push (@output, $result);
    }

    
    for my $dns_record (@{$old_dns_zone[0]}) {
        if (!@{$subdomains_for_this_addon_domain[0]}) {
            my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminAddDNSRecord',
                {
                    "user" => $Cpanel::user,
                    "domain" => $domain,
                    "dns_record" => $dns_record,
                });

            push (@output, $result);
        }
        else {
            for my $subdomain (@{$subdomains_for_this_addon_domain[0]}) {
                if (index($dns_record->{'name'}, $subdomain->{'subdomain'}) == -1) {
                    my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminAddDNSRecord',
                        {
                        "user" => $Cpanel::user,
                        "domain" => $domain,
                        "dns_record" => $dns_record,
                    });

                    push (@output, $result);
                    last;
                }
            }
        }
    }

    for my $dns_record (@records_to_keep) {
        my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminAddDNSRecord',
        {
            "user" => $Cpanel::user,
            "domain" => $domain,
            "dns_record" => $dns_record,
        });

        #push (@output, $result);
    }

    return @output;
}






sub test_function {
    my ( $args, $result ) = @_;

    # ARRAY FOR LOGGING OUTPUT
    my @output;

    my $old_domain = %Cpanel::CPDATA{DNS};
    my $new_domain = $args->get('new_domain');
    my $user = $Cpanel::user;

    my $url = 'https://www.oderland.se/clients/includes/api.php';
    my $search_header = [
        'Content-Type' => 'application/x-www-form-urlencoded'
    ];
    my $search_content = {
        'action' => 'GetClientsProducts',
        'username' => 'IDENTIFIER_OR_ADMIN_USERNAME',
        'password' => 'SECRET_OR_HASHED_PASSWORD',
        'domain' => $old_domain,
        'username2' => $user,
        'responsetype' => 'json',
    };
    $search_content = encode_json $search_content;

    my $search_request = HTTP::Request->new('POST', $url, $search_header, $search_content);

    #my $ua = LWP::UserAgent->new;
    #my $search_response = $ua->request($search_request);
    #push(@output, {"Output: search_response" => $search_response});

    my $search_response = {
        "result" => "success",
        "clientid" => "1",
        "serviceid" => "null",
        "pid" => "null",
        "domain" => "null",
        "totalresults" => "2",
        "startnumber" => 0,
        "numreturned" => 2,
        "products" => {
        "product" => [
            {
                "id" => "1",
                "clientid" => "1",
                "orderid" => "1",
                "pid" => "1",
                "regdate" => "2015-01-01",
                "name" => "Starter",
                "translated_name" => "Starter",
                "groupname" => "Shared Hosting",
                "translated_groupname" => "Shared Hosting",
                "domain" => "demodomain.com",
                "dedicatedip" => "",
                "serverid" => "1",
                "servername" => "Saturn",
                "serverip" => "1.2.3.4",
                "serverhostname" => "saturn.example.com",
                "suspensionreason" => "",
                "firstpaymentamount" => "12.95",
                "recurringamount" => "12.95",
                "paymentmethod" => "authorize",
                "paymentmethodname" => "Credit Card",
                "billingcycle" => "Monthly",
                "nextduedate" => "2016-11-25",
                "status" => "Terminated",
                "username" => "demodoma",
                "password" => "xxxxxxxx",
                "subscriptionid" => "",
                "promoid" => "0",
                "overideautosuspend" => "",
                "overidesuspenduntil" => "0000-00-00",
                "ns1" => "",
                "ns2" => "",
                "assignedips" => "",
                "notes" => "",
                "diskusage" => "0",
                "disklimit" => "0",
                "bwusage" => "0",
                "bwlimit" => "0",
                "lastupdate" => "0000-00-00 00 =>00 =>00",
                "customfields" => {
                    "customfield" => []
                },
                "configoptions" => {
                    "configoption" => []
                }
            },
            {
                "id" => "2",
                "clientid" => "1",
                "orderid" => "2",
                "pid" => "3",
                "regdate" => "2015-05-20",
                "name" => "Plus",
                "translated_name" => "Plus",
                "groupname" => "Shared Hosting",
                "translated_groupname" => "Shared Hosting",
                "domain" => "sebode-222.hemsida.eu",
                "dedicatedip" => "",
                "serverid" => "2",
                "servername" => "Pluto",
                "serverip" => "2.3.4.5",
                "serverhostname" => "cpanel-dev-cl7.oderland.com",
                "suspensionreason" => "",
                "firstpaymentamount" => "24.95",
                "recurringamount" => "24.95",
                "paymentmethod" => "paypal",
                "paymentmethodname" => "PayPal",
                "billingcycle" => "Monthly",
                "nextduedate" => "2017-01-20",
                "status" => "Active",
                "username" => "sebodete",
                "password" => "xxxxxxxx",
                "subscriptionid" => "",
                "promoid" => "0",
                "overideautosuspend" => "",
                "overidesuspenduntil" => "0000-00-00",
                "ns1" => "",
                "ns2" => "",
                "assignedips" => "",
                "notes" => "",
                "diskusage" => "0",
                "disklimit" => "0",
                "bwusage" => "0",
                "bwlimit" => "0",
                "lastupdate" => "0000-00-00 00 =>00 =>00",
                "customfields" => {
                    "customfield" => []
                },
                "configoptions" => {
                    "configoption" => [
                        {
                            "id" => "1",
                            "option" => "Sample Config Option",
                            "type" => "dropdown",
                            "value" => "Selected option value"
                        }
                    ]
                }
            }
        ]}
    };

    if ($search_response->{'result'} ne 'success') { return; }



    for my $service (@{$search_response->{'products'}->{'product'}}) {
        if ($service->{'domain'} ne $old_domain) { next; }
        if ($service->{'serverhostname'} ne hostname) { next; }
        if ($service->{'username'} ne $user) { next; }
        if ($service->{'status'} ne 'Active') { next; }

        my $update_domain_header = [
            'Content-Type' => 'application/x-www-form-urlencoded'
        ];

        my $update_domain_content = {
            'action' => 'UpdateClientProduct',
            'username' => 'IDENTIFIER_OR_ADMIN_USERNAME',
            'password' => 'SECRET_OR_HASHED_PASSWORD',
            'domain' => $new_domain,
            'serviceid' => $service->{'id'},
            'responsetype' => 'json',
        };
        $update_domain_content = encode_json $update_domain_content;

        my $update_domain_request = HTTP::Request->new('POST', $url, $update_domain_header, $update_domain_content);
        #my $update_domain_response = $ua->request($update_domain_request);
        #push(@output, {"Output: update_domain_response" => $update_domain_response});

        push(@output, {"Output: search_response" => $service});

        last;
    }

    #push (@output, {"Output: AdminUpdateWHMCSDomainName" => Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminUpdateWHMCSDomainName', 
    #{ 
    #    "user" => $Cpanel::user, "old_domain" => $old_domain, "new_domain" => $new_domain
    #})});

    $result->data(\@output);
    return 1;
}

sub reset_domains_and_dns {
    my ( $args, $result ) = @_;

    my @addon_domains = ('sebode-222.hemsida.eu', 'sebode-333.hemsida.eu');
    my $primary_domain = 'sebode-111.hemsida.eu';

    my @output;

    my $domain_info = Cpanel::API::_execute( 'DomainInfo', 'list_domains')->{'data'};
    push (@output, {'Output: list_domains' => $domain_info});

    # RESET DNS ZONE
    my @reset_zone_output;
    my $result_main_domain = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminResetDNSZone',
        { 
            "user" => $Cpanel::user,
            "domain" => $domain_info->{'main_domain'}
        });
    push (@reset_zone_output, $domain_info->{'main_domain'});
    push (@reset_zone_output, $result_main_domain);

    for my $domain (@{$domain_info->{'addon_domains'}}) {
        my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminResetDNSZone',
            { 
                "user" => $Cpanel::user,
                "domain" => $domain
            });

        push (@reset_zone_output, $domain);
        push (@reset_zone_output, $result);
    }

    push (@output, {'Output: reset_zones' => \@reset_zone_output});


    $result->data(\@output);
    return 1;
}

sub backup_etc_folders {
    my ( $old_domain, $new_domain ) = @_;
    my $user = $Cpanel::user;

    my $command = "cp -a /home/" . $user . "/etc/" . $old_domain . "{,-bak} && cp -a /home/" . $user . "/etc/" . $new_domain . "{,-bak}";
    my $command_output = `$command`;

    return $command_output;
}

sub restore_etc_folders {
    my ( $old_domain, $new_domain ) = @_;
    my $user = $Cpanel::user;

    my $command = "rm -rf /home/" . $user . "/etc/" . $old_domain . "&& rm -rf /home/" . $user . "/etc/" . $new_domain;
    my $command_output = `$command`;
    
    $command = "mv /home/" . $user . "/etc/" . $old_domain . "{-bak,} && mv /home/" . $user . "/etc/" . $new_domain . "{-bak,}";
    $command_output = $command_output . `$command`;

    return $command_output;
}

sub get_email_accounts {
    my $email_accounts = Cpanel::API::_execute('Email', 'list_pops');
    return $email_accounts;
}


1;