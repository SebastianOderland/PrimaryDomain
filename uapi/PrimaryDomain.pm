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
    









    # GET THE DNS ZONES
    my @primary_domain_zone_output = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZones', { "old_domain" => $old_domain, "new_domain" => $new_domain});
    my $old_domain_zone = @primary_domain_zone_output[0];
    my $new_primary_domain_zone = @primary_domain_zone_output[1];


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



    # IMPORT DNS ZONES


    my $returns = $change_primary_domain_output;
    $result->data($returns);

    return 1;
}

sub does_dns_record_exist_in_zone {
    my ($dns_record, @dns_zone) = @_;

    for my $new_dns_record (@{$dns_zone[0]}) {
        if ($new_dns_record->{type} != $dns_record->{type}) {
            next;
        }
        if ($new_dns_record->{TTL} != $dns_record->{TTL}) {
            next;
        }
        if ($new_dns_record->{name} != $dns_record->{name}) {
            next;
        }
        while (my ($key, $value) = each %{$new_dns_record}) {
            if ($key eq "type") {
                #given($value) {
                    #when ("A") {
                    #    $output_hash{$dns_record->{Line}} = {"type" => $dns_record->{type}, "TTL" => $dns_record->{TTL}, "name" => $dns_record->{name}, "address" => $dns_record->{address}};
                    #}
                    #when ("CNAME") {
                    #    $output_hash{$dns_record->{Line}} = {"type" => $dns_record->{type}, "TTL" => $dns_record->{TTL}, "name" => $dns_record->{name}, "cname" => $dns_record->{cname}};
                    #}
                    #when ("MX") {
                    #    $output_hash{$dns_record->{Line}} = {"type" => $dns_record->{type}, "TTL" => $dns_record->{TTL}, "name" => $dns_record->{name}, "preference" => $dns_record->{preference}, "exchange" => $dns_record->{exchange}};
                    #}
                    #when ("TXT") {
                    #    $output_hash{$dns_record->{Line}} = {"type" => $dns_record->{type}, "TTL" => $dns_record->{TTL}, "name" => $dns_record->{name}, "txtdata" => $dns_record->{txtdata}};
                    #}
                #}
            }
        }
    }

    return "hehe";
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
    for my $dns_record (@{$old_new_domain_dns_zone[0]}) {
        while (my ($key, $value) = each %{$dns_record}) {
            if (index($key ))
            my $temp = does_dns_record_exist_in_zone($dns_record, @new_new_domain_dns_zone);
            $output_string = "$output_string | $temp";
        }
    }
    
    #Slash_And_Or_Dashes99

    $result->data({"output_string" => $output_string, "output_hash" => \%output_hash, "output_subdomain" => \@subdomain});

    return 1;
}

1;