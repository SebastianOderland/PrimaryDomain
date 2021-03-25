
#Cpanel::Api2::Exec::api2_preexec("AddonDomain", "deladdondomain");
#$command_output = Cpanel::Api2::Exec::api2_exec("AddonDomain", "deladdondomain",
    #{
    #    "domain" => $new_domain, 
    #    "subdomain" => "jpadjpofa_sebode-test2.hemsida.eu"
    #}, "api2_deladdondomain");
#$command_output = Cpanel::Api2::Exec::api2_exec("AddonDomain", "deladdondomain", {"domain" => $new_domain, "subdomain" => "jpadjpofa_sebode-test2.hemsida.eu"});#$new_domain_servername});
#Cpanel::Api2::Exec::api2_postexec("AddonDomain", "deladdondomain");

    # CREATE THE PRIMARY DOMAIN
    #my $change_primary_domain_output = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminChangePrimaryDomain', { "user" => $Cpanel::user, "new_domain" => $new_domain});


    
    #my $output_string = remove_dns_records($old_domain, \@subdomains, \@new_old_domain_dns_zone, 1);



    for my $dns_record (@{$old_dns_zone[0]}) {
        my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminAddDNSRecord',
        {
            "user" => $Cpanel::user,
            "domain" => $domain,
            "dns_record" => $dns_record,
        });

        push (@output, $result);
    }



sub delete_dns_records {
    my ($domain) = $_;

    my @records_to_remove;

    for my $dns_record (@{$new_dns_zones[0][0]}) {
        push (@records_to_remove, $dns_record->{Line});
    }

    # Sorts the array in reverse, so it deletes the last record first.
    # If we don't, the line numbers will be incorrect.
    @records_to_remove = sort { $b <=> $a } @records_to_remove;

    for my $record (@records_to_remove) {
        my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminRemoveDNSRecord',
        {
            "user" => $Cpanel::user,
            "domain" => $domain,
            "line" => $record,
        });
    }
}




    my $old_domain_info = Cpanel::API::_execute( 'DomainInfo', 'single_domain_data',
    {
        'domain'    => $old_domain,
        'return_https_redirect_status' => '0',
    })->{data};

    my $old_domain_servername = $old_domain_info->{servername};

    $new_domain_servername =~ s/.$old_domain/_$old_domain/g;







        # OLD

    # Remove all DNS Records for the old primary domain
    my @records_to_remove;

    for my $new_dns_record (@{$new_old_domain_dns_zone[0]}) {
        push (@records_to_remove, $new_dns_record->{Line});
    }

    @records_to_remove = sort { $b <=> $a } @records_to_remove;

    for my $record (@records_to_remove) {
        my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminRemoveDNSRecord',
        {
            "user" => $Cpanel::user,
            "domain" => $old_domain,
            "line" => $record,
        });
        #$output_string = "$output_string $record";
    }

    for my $dns_record (@{$old_old_domain_dns_zone[0]}) {
        # ADD DNS RECORD
        my $boolean = 0;
        $output_string = "$output_string $dns_record->{name} ======= ";
        for my $subdomain (@subdomains) {
            if (index($dns_record->{name}, $subdomain) != -1) {
                $output_string = "$output_string 1";
                $boolean = 1;
                last;
            }
            $output_string = "$output_string 0";
        }
        if($boolean == 0) {
            my $new_dns_record = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminAddDNSRecord',
            {
                "user" => $Cpanel::user,
                "domain" => $old_domain,
                "dns_record" => $dns_record,
            });
            $output_string = $output_string . "!!!ADDED!!! $dns_record->{name}";
        }
    }

    # NEW
    $output_string = $output_string . remove_dns_records($new_domain, \@subdomains, \@new_new_domain_dns_zone, 0);    
    for my $dns_record (@{$old_new_domain_dns_zone[0]}) {
        # ADD DNS RECORD
        my $new_dns_record = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminAddDNSRecord',
        {
            "user" => $Cpanel::user,
            "domain" => $new_domain,
            "dns_record" => $dns_record,
        });
        #$output_string = "$output_string ADD $dns_record->{name} = $dns_record->{type} |";
    }