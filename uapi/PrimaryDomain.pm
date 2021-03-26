package Cpanel::API::PrimaryDomain;

use strict;
use warnings;
use JSON;
use JSON::XS qw( decode_json );

use Cpanel::AdminBin::Call;
use Cpanel::Api2::Exec;

use Whostmgr::API::1::DNS ();
use feature qw/switch/;


sub get_info() {
    my ( $args, $result ) = @_;

    my @wanted    = $args->get_multiple('name');
    my $variables = {
        %Cpanel::CPDATA,
        %Cpanel::USERDATA,
        cpanel_root_directory => $Cpanel::CONF{root},
    };

    my %list_of_output = ();

    foreach my $key (keys %Cpanel::CPDATA)
    {
        my $value = %Cpanel::CPDATA{$key};
        $list_of_output{$key} = $value;
        #push @list_of_output, "$key = $value"
    }

    foreach my $key (keys %Cpanel::USERDATA)
    {
        my $value = %Cpanel::USERDATA{$key};
        $list_of_output{$key} = $value;
        #push @list_of_output, "$key = $value"
    }

    foreach my $key (keys %Cpanel::CONF)
    {
        my $value = %Cpanel::CONF{$key};
        $list_of_output{$key} = $value;
        #push @list_of_output, "$key = $value"
    }

    my $returns = %list_of_output;
    $result->data(%list_of_output);
}

sub change_primary_domain() {
    my ( $args, $result ) = @_;

    my @wanted    = $args->get_multiple('name');
    my $variables = {
        %Cpanel::CPDATA,
        %Cpanel::USERDATA,
        cpanel_root_directory => $Cpanel::CONF{root},
    };

    my $list_of_output = "";

    foreach my $key (keys %Cpanel::CPDATA)
    {
        my $value = %Cpanel::CPDATA{$key};
        $list_of_output = $list_of_output . "$key = $value     |||||       \n";
    }

    my $new_domain = @wanted[0];
    my $old_domain = %Cpanel::CPDATA{DNS};

    if ($new_domain eq $old_domain) {
        $Cpanel::CPERROR{'changeprimarydomain'} = "Old and new primary domain are the same!";
        return;
    }

    my $new_domain_info = Cpanel::API::_execute( 'DomainInfo', 'single_domain_data',
    {
        'domain'    => $new_domain,
        'return_https_redirect_status' => '0',
    })->{data};

    my $old_domain_info = Cpanel::API::_execute( 'DomainInfo', 'single_domain_data',
    {
        'domain'    => $old_domain,
        'return_https_redirect_status' => '0',
    })->{data};

    my $new_domain_servername = $new_domain_info->{servername};
    my $old_domain_servername = $old_domain_info->{servername};

    $new_domain_servername =~ s/.$old_domain/_$old_domain/g;
    
    my $deladdondomain_output;
    my $change_primary_domain_output;
    









    # GET THE OLD DNS ZONES
    my @old_domain_zones = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZones', { "user" => $Cpanel::user, "old_domain" => $old_domain, "new_domain" => $new_domain});
    my @old_old_domain_dns_zone = @old_domain_zones[0]->{data}->{zone}[0]->{record};
    my @old_new_domain_dns_zone = @old_domain_zones[1]->{data}->{zone}[0]->{record};


    # DELETE THE NEW PRIMARY DOMAIN
    if ($new_domain_info->{type} eq "addon_domain")
    {
        my $command = "cpapi2 AddonDomain deladdondomain domain=$new_domain subdomain=$new_domain_servername";
        $deladdondomain_output = `$command`;
        #Cpanel::Api2::Exec::api2_preexec("AddonDomain", "deladdondomain");
        #$command_output = Cpanel::Api2::Exec::api2_exec("AddonDomain", "deladdondomain",
            #{
            #    "domain" => $new_domain, 
            #    "subdomain" => "jpadjpofa_sebode-test2.hemsida.eu"
            #}, "api2_deladdondomain");
        #$command_output = Cpanel::Api2::Exec::api2_exec("AddonDomain", "deladdondomain", {"domain" => $new_domain, "subdomain" => "jpadjpofa_sebode-test2.hemsida.eu"});#$new_domain_servername});
        #Cpanel::Api2::Exec::api2_postexec("AddonDomain", "deladdondomain");
    }
    elsif ($new_domain_info->{domain} eq "") {
        my $change_primary_domain_output = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminChangePrimaryDomain', { "user" => $Cpanel::user, "new_domain" => $new_domain});
        
        my $returns = $change_primary_domain_output;
        $result->data($returns);
        return 1;
    }
    else
    {
        $Cpanel::CPERROR{'changeprimarydomain'} = "[$new_domain] is not an Addon Domain!";
        return 0;
    }



    # CREATE THE PRIMARY DOMAIN
    my $change_primary_domain_output = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminChangePrimaryDomain', { "user" => $Cpanel::user, "new_domain" => $new_domain});



    # RECREATE THE OLD DOMAIN AS ADDON
    my $old_domain_info_documentroot = $old_domain_info->{documentroot};
    my $command = "cpapi2 AddonDomain addaddondomain dir=public_html newdomain=$old_domain subdomain=$old_domain_servername";
    my $addaddondomain_output = `$command`;



    # GET THE NEW DNS ZONES
    my @new_domain_zones = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZones', { "user" => $Cpanel::user, "old_domain" => $old_domain, "new_domain" => $new_domain});
    my @new_old_domain_dns_zone = @new_domain_zones[0]->{data}->{zone}[0]->{record};
    my @new_new_domain_dns_zone = @new_domain_zones[1]->{data}->{zone}[0]->{record};

    # GET SUBDOMAINS
    my $listallsubdomains = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetSubDomains', { "user" => $Cpanel::user });
    my @subdomains;
    for my $index (@{$listallsubdomains->{cpanelresult}->{data}}) {
        while (my ($key, $value) = each %{$index}) {
            if ($key eq "subdomain") {
                push(@subdomains, $value);
            }
        }
    }

    my $output_string = "";
    #my $output_string = remove_dns_records($old_domain, \@subdomains, \@new_old_domain_dns_zone, 1);    

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

    my %returns = ();
    $returns{"old_old_zone" => \@old_old_domain_dns_zone};
    #$returns"old_new_zone" => $output_string};
    #$returns{"new_old_zone" => $output_string};
    #$returns{"new_new_zone" => $output_string};
    $result->data(\%returns);

    return 1;
}
    
    #Slash_And_Or_Dashes99

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
    my ( $args, $result ) = @_;

    my @wanted    = $args->get_multiple('name');
    my $variables = {
        %Cpanel::CPDATA,
        %Cpanel::USERDATA,
        cpanel_root_directory => $Cpanel::CONF{root},
    };


    my $old_domain = %Cpanel::CPDATA{DNS};
    my $new_domain = @wanted[0];

    my $old_domain_info = Cpanel::API::_execute('DomainInfo', 'single_domain_data', {
        'domain'    => $old_domain,
        'return_https_redirect_status' => '0',
    })->{data};

    my $new_domain_info = Cpanel::API::_execute('DomainInfo', 'single_domain_data', {
        'domain'    => $new_domain,
        'return_https_redirect_status' => '0',
    })->{data};



    



    my $output_string = "";
    my %output_hash;
    my %old_old_dns_records;

    # GET SUBDOMAINS
    my $listallsubdomains = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetSubDomains', { "user" => $Cpanel::user });
    my @subdomains;
    for my $index (@{$listallsubdomains->{cpanelresult}->{data}}) {
        while (my ($key, $value) = each %{$index}) {
            if ($key eq "subdomain") {
                push(@subdomains, $value);
            }
        }
    }


    # GET THE OLD DNS ZONES
    my @old_domain_zones = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZones', { "user" => $Cpanel::user, "old_domain" => $old_domain, "new_domain" => $new_domain});
    my @old_old_domain_dns_zone = @old_domain_zones[0]->{data}->{zone}[0]->{record};
    my @old_new_domain_dns_zone = @old_domain_zones[1]->{data}->{zone}[0]->{record};

    # GET THE NEW DNS ZONES
    my @new_domain_zones = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZones', { "user" => $Cpanel::user, "old_domain" => $old_domain, "new_domain" => $new_domain});
    my @new_old_domain_dns_zone = @new_domain_zones[0]->{data}->{zone}[0]->{record};
    my @new_new_domain_dns_zone = @new_domain_zones[1]->{data}->{zone}[0]->{record};

    # IMPORT DNS-RECORDS
    $output_string = $output_string . import_dns_zone($old_domain, \@subdomains, \@old_old_domain_dns_zone, \@new_old_domain_dns_zone);
    $output_string = $output_string . import_dns_zone($new_domain, \@subdomains, \@old_new_domain_dns_zone, \@new_new_domain_dns_zone);
    
    #Slash_And_Or_Dashes99

    $result->data({"output_string" => $output_string, "output_hash" => \%output_hash, "output_subdomain" => \@subdomains, "old_new" => scalar @old_old_domain_dns_zone, "new_new" => scalar @new_old_domain_dns_zone});

    return 1;
}
    #Slash_And_Or_Dashes99

1;