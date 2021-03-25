sub does_dns_record_exist {
    my ($dns_record, $dns_zone) = @_;

    my @dns_zone = @{$dns_zone};
 
    for my $new_dns_record (@{$dns_zone}) {
        if ($new_dns_record->{type} ne $dns_record->{type}) {
            next;
        }
        if ($new_dns_record->{name} ne $dns_record->{name}) {
            next;
        }
        return $new_dns_record->{Line};
    }

    return 0;
}

sub remove_dns_records {
    my ($domain, $subdomains, $dns_zone, $subdomain_switch) = @_;

    my @subdomains = @{$subdomains};
    my @dns_zone = @{$dns_zone};

    my $output = "";
    my @records_to_remove = ();

    for my $new_dns_record (@{$dns_zone[0]}) {
        my $boolean = 0;
        for my $subdomain (@{$subdomains}) {
            if (index($new_dns_record->{name}, $subdomain) != -1) {
                #$output = "$output $new_dns_record->{type} |||";
                $boolean = 1;
                last;
            }
        }
        if($boolean == $subdomain_switch) {
            #$output = "$output $new_dns_record->{name} |";
            push (@records_to_remove, $new_dns_record->{Line});
        }
    }

    @records_to_remove = sort { $b <=> $a } @records_to_remove;

    for my $record (@records_to_remove) {
        my $result = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminRemoveDNSRecord',
        {
            "user" => $Cpanel::user,
            "domain" => $domain,
            "line" => $record,
        });
        #$output = "$output $result";
    }

    return $output;
}

sub import_dns_zone {

    my ($domain, $subdomains, $old_dns_zone, $new_dns_zone, $subdomain_switch) = @_;
 
    my $output_string = "";

    my @subdomains = @{$subdomains};
    my @old_dns_zone = @{$old_dns_zone};
    my @new_dns_zone = @{$new_dns_zone};

    $output_string = remove_dns_records($domain, \@subdomains, \@new_dns_zone, $subdomain_switch);    


    for my $dns_record (@{$old_dns_zone[0]}) {
        # ADD DNS RECORD
        my $new_dns_record = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminAddDNSRecord',
        {
            "user" => $Cpanel::user,
            "domain" => $domain,
            "dns_record" => $dns_record,
        });
        $output_string = "$output_string ADD $dns_record->{name} = $dns_record->{type} |";
    }

    return $output_string;

}

sub get_dns_zone() {
    my ( $domain ) = @_;

    my $dns_zone = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZones', { "user" => $Cpanel::user, "domain" => $domain });

    return $dns_zone;
}
    #Slash_And_Or_Dashes99

1;