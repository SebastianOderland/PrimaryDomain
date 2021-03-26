package Cpanel::API::PrimaryDomain;

use strict;
use warnings;
use Data::Dumper;

use Cpanel::AdminBin::Call;
use Cpanel::Api2::Exec;
use Whostmgr::API::1::DNS();
use feature qw/switch/;
use List::Util qw(any);

sub plugin_info {
    my ( $args, $result ) = @_;
    my @output;
    local $Data::Dumper::Terse = 1;

    my $primary_domain = %Cpanel::CPDATA{'DNS'};
    push (@output, {'primary_domain' => $primary_domain});
    my $addon_domains = Dumper(Cpanel::API::_execute( 'DomainInfo', 'list_domains')->{'data'}->{'addon_domains'});
    push (@output, {'addon_domains' => $addon_domains});
    #my $param = join(q{, }, map{qq{$_ => $hash{$_}}} keys %hash);
 
    $result->data(\@output);
    return 1;
}

sub change_primary_domain {
    my ( $args, $result ) = @_;

    # ARRAY FOR LOGGING OUTPUT
    my @output;

    my $old_domain = %Cpanel::CPDATA{DNS};
    my $new_domain = $args->get('new_domain');
    
    push (@output, {'Output: old_domain' => $old_domain});
    push (@output, {'Output: new_domain' => $new_domain});

    if ($old_domain eq $new_domain) {
        $Cpanel::CPERROR{'changeprimarydomain'} = 'Old and new primary domain are the same!';
        return;
    }

    my $old_domain_info = Cpanel::API::_execute( 'DomainInfo', 'single_domain_data',
    {
        'domain'    => $old_domain,
    })->{'data'};

    my $new_domain_info = Cpanel::API::_execute( 'DomainInfo', 'single_domain_data',
    {
        'domain'    => $new_domain,
    })->{'data'};

    if ($old_domain_info->{'documentroot'} ne $new_domain_info->{'documentroot'}) {
        $Cpanel::CPERROR{'changeprimarydomain'} = 'The current Addon Domain and the current Primary Domain needs to have the same Documentroot!';
        return;
    }


    # STORE OLD SUBDOMAINS
    my @old_subdomains = get_subdomains();
    push (@output, {"Output: get_old_subdomains" => \@old_subdomains});

    # STORE OLD DNS ZONES
    my @old_dns_zone_for_old_domain = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZone', { "user" => $Cpanel::user, "domain" => $old_domain});
    my @old_dns_zone_for_new_domain = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZone', { "user" => $Cpanel::user, "domain" => $new_domain});


    # DELETE ALL SUBDOMAINS ON THE ADDON DOMAIN
    push (@output, {"Output: delete_subdomains" => delete_subdomains($new_domain, \@old_subdomains)});


    # DELETE CURRENT ADDON DOMAIN
    push (@output, {"Output: delete_addon_domain" => delete_addon_domain($new_domain)});


    # CHANGE PRIMARY DOMAIN
    push (@output, {"Output: change_primary_domain" => Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminChangePrimaryDomain',{ "user" => $Cpanel::user,"new_domain" => $new_domain })});


    # CREATE NEW ADDON DOMAIN
    push (@output, {"Output: create_addon_domain" => create_addon_domain($old_domain)});


    # STORE NEW DNS ZONES
    my @new_dns_zone_for_old_domain = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZone', { "user" => $Cpanel::user, "domain" => $old_domain});
    my @new_dns_zone_for_new_domain = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZone', { "user" => $Cpanel::user, "domain" => $new_domain});


    # STORE NEW SUBDOMAINS
    my @new_subdomains = get_subdomains();
    push (@output, {"Output: get_new_subdomains" => \@new_subdomains});
    my @subdomains = (@old_subdomains, @new_subdomains);


    # IMPORT OLD DNS RECORDS TO NEW DNS ZONE
    my @fix_old_output = fix_old_primary_domain_dns_zone($old_domain, \@old_subdomains, \@old_dns_zone_for_old_domain, \@new_dns_zone_for_old_domain);
    push (@output, {"Output: fix_old_primary_domain_dns_zone" => \@fix_old_output});

    my @fix_new_output = fix_new_primary_domain_dns_zone($new_domain, \@subdomains, \@old_dns_zone_for_new_domain, \@new_dns_zone_for_new_domain);
    push (@output, {"Output: fix_new_primary_domain_dns_zone" => \@fix_new_output});


    $result->data(\@output);
    return 1;
}

 #Slash_And_Or_Dashes99

sub get_subdomains {
    my $subdomains_output = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetSubDomains', { "user" => $Cpanel::user });
    my @subdomains;
    for my $index (@{$subdomains_output->{"cpanelresult"}->{"data"}}) {
        push(@subdomains, {'domainkey' => $index->{'domainkey'}, 'subdomain' => $index->{'subdomain'}, 'domain' => $index->{'domain'}, 'documentroot' => $index->{'basedir'}});
    }
    return @subdomains;
}

sub delete_subdomains {
    my ( $domain, $subdomains ) = @_;
    my @subdomains = @{$subdomains};

    my @output;

    for my $subdomain (@{$subdomains}) { 
        if (index ($subdomain->{'domain'}, $domain) != -1) {
            my $command = "cpapi2 SubDomain delsubdomain domain=$subdomain->{'domain'}";
            my $command_output = `$command`;
            push (@output, {'result' => $command_output});
        }
    }

    return \@output;
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
    my ($domain, $subdomains, $old_dns_zone, $new_dns_zone) = @_;
    # REMOVE ALL DNS RECORDS

    my @output;
    my @subdomains = @{$subdomains};
    my @old_dns_zone = @{$old_dns_zone};
    my @new_dns_zone = @{$new_dns_zone};

    my @records_to_remove = ();
    my @records_to_keep = ();

    for my $new_dns_record (@{$new_dns_zone[0]}) {
        push (@records_to_remove, $new_dns_record->{'Line'});
        for my $subdomain (@{$subdomains}) {
            # If the record name contains a subdomain, don't delete it.
            if (index($new_dns_record->{'name'}, $subdomain->{'subdomain'}) != -1) {
                push (@records_to_keep, $new_dns_record);
                last;
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

        push (@output, $result);
    }

    for my $dns_record (@{$old_dns_zone[0]}) {
        #for my $subdomain (@{$subdomains}) {
        #if (index($dns_record->{'name'}, $subdomain->{'subdomain'}) != -1) {
        #}
        #my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminAddDNSRecord',
        #{
        #    "user" => $Cpanel::user,
        #    "domain" => $domain,
        #    "dns_record" => $dns_record,
        #});

        #push (@output, $result);
    }

    for my $dns_record (@records_to_keep) {
        my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminAddDNSRecord',
        {
            "user" => $Cpanel::user,
            "domain" => $domain,
            "dns_record" => $dns_record,
        });

        push (@output, $result);
    }

    return @output;
}

sub reset_domains_and_dns {
    my ( $args, $result ) = @_;

    my @addon_domains = ('sebode-222.hemsida.eu', 'sebode-333.hemsida.eu');
    my $primary_domain = 'sebode-111.hemsida.eu';

    # ARRAY FOR LOGGING OUTPUT
    my @output;

    #push (@output, {"Output: change_primary_domain-1" => Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminChangePrimaryDomain',{ "user" => $Cpanel::user,"new_domain" => "sebode-temp.hemsida.eu" })});
    
    my $domain_info = Cpanel::API::_execute( 'DomainInfo', 'list_domains')->{'data'}->{'addon_domains'};

    push (@output, {'Output: list_domains' => $domain_info});

    my @delete_addon_domains_output;
    for my $domain (@{$domain_info}) {
        my $result = delete_addon_domain($domain);

        push (@delete_addon_domains_output, $domain);
        push (@delete_addon_domains_output, $result);
    }
    push (@output, {'Output: delete_addon_domains' => \@delete_addon_domains_output});

    my @create_addon_domains_output;
    for my $domain (@addon_domains) {
        my $result = create_addon_domain($domain);

        push (@create_addon_domains_output, $result);
    }
    push (@output, {'Output: create_addon_domains' => \@create_addon_domains_output});

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
    push (@output, {'Output: delete_addon_domains' => \@reset_zone_output});

    push (@output, {"Output: change_primary_domain-2" => Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminChangePrimaryDomain',{ "user" => $Cpanel::user,"new_domain" => $primary_domain })});

    $result->data(\@output);
    return 1;
}

1;