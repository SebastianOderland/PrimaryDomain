package Cpanel::API::PrimaryDomain;

use strict;
use warnings;
use JSON;
use JSON::XS qw( decode_json );

use Cpanel::AdminBin::Call;
use Cpanel::Api2::Exec;

use Whostmgr::API::1::DNS ();

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

    my $new_primary_domain = @wanted[0];
    my $old_primary_domain = %Cpanel::CPDATA{DNS};

    if ($new_primary_domain eq $old_primary_domain) {
        $Cpanel::CPERROR{'changeprimarydomain'} = "Old and new primary domain are the same!";
        return;
    }

    my $new_domain_info = Cpanel::API::_execute( 'DomainInfo', 'single_domain_data',
    {
        'domain'    => $new_primary_domain,
        'return_https_redirect_status' => '0',
    })->{data};

    my $old_domain_info = Cpanel::API::_execute( 'DomainInfo', 'single_domain_data',
    {
        'domain'    => $old_primary_domain,
        'return_https_redirect_status' => '0',
    })->{data};

    my $new_domain_servername = $new_domain_info->{servername};
    my $old_domain_servername = $old_domain_info->{servername};

    $new_domain_servername =~ s/.$old_primary_domain/_$old_primary_domain/g;
    
    my $deladdondomain_output;
    my $change_primary_domain_output;
    









    # GET THE DNS ZONES
    my @primary_domain_zone_output = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZones', { "old_primary_domain" => $old_primary_domain, "new_primary_domain" => $new_primary_domain});
    my $old_primary_domain_zone = @primary_domain_zone_output[0];
    my $new_primary_domain_zone = @primary_domain_zone_output[1];


    # DELETE THE NEW PRIMARY DOMAIN
    if ($new_domain_info->{type} eq "addon_domain")
    {
        my $command = "cpapi2 AddonDomain deladdondomain domain=$new_primary_domain subdomain=$new_domain_servername";
        $deladdondomain_output = `$command`;
        #Cpanel::Api2::Exec::api2_preexec("AddonDomain", "deladdondomain");
        #$command_output = Cpanel::Api2::Exec::api2_exec("AddonDomain", "deladdondomain",
            #{
            #    "domain" => $new_primary_domain, 
            #    "subdomain" => "jpadjpofa_sebode-test2.hemsida.eu"
            #}, "api2_deladdondomain");
        #$command_output = Cpanel::Api2::Exec::api2_exec("AddonDomain", "deladdondomain", {"domain" => $new_primary_domain, "subdomain" => "jpadjpofa_sebode-test2.hemsida.eu"});#$new_domain_servername});
        #Cpanel::Api2::Exec::api2_postexec("AddonDomain", "deladdondomain");
    }
    elsif ($new_domain_info->{domain} eq "") {
        my $change_primary_domain_output = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminChangePrimaryDomain', { "user" => $Cpanel::user, "new_primary_domain" => $new_primary_domain});
        
        my $returns = $change_primary_domain_output;
        $result->data($returns);
        return 1;
    }
    else
    {
        $Cpanel::CPERROR{'changeprimarydomain'} = "[$new_primary_domain] is not an Addon Domain!";
        return 0;
    }



    # CREATE THE PRIMARY DOMAIN
    my $change_primary_domain_output = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminChangePrimaryDomain', { "user" => $Cpanel::user, "new_primary_domain" => $new_primary_domain});



    # RECREATE THE OLD DOMAIN AS ADDON
    my $old_domain_info_documentroot = $old_domain_info->{documentroot};
    my $command = "cpapi2 AddonDomain addaddondomain dir=public_html newdomain=$old_primary_domain subdomain=$old_domain_servername";
    my $addaddondomain_output = `$command`;



    # IMPORT DNS ZONES
    for my $record ($old_primary_domain_zone->{data}->{zone}[0]->{record}) {
        
    }


    my $returns = $change_primary_domain_output;
    $result->data($returns);

    return 1;
}

sub get_dns_zone() {
    my ( $args, $result ) = @_;

    my @wanted    = $args->get_multiple('name');
    my $variables = {
        %Cpanel::CPDATA,
        %Cpanel::USERDATA,
        cpanel_root_directory => $Cpanel::CONF{root},
    };

    my $list_of_output = "";

    my $old_primary_domain = %Cpanel::CPDATA{DNS};
    my $new_primary_domain = @wanted[0];

    my $old_domain_info = Cpanel::API::_execute( 'DomainInfo', 'single_domain_data',
    {
        'domain'    => $old_primary_domain,
        'return_https_redirect_status' => '0',
    })->{data};

    my $new_domain_info = Cpanel::API::_execute( 'DomainInfo', 'single_domain_data',
    {
        'domain'    => $new_primary_domain,
        'return_https_redirect_status' => '0',
    })->{data};



    




    # GET THE DNS ZONES
    my @primary_domain_zone_output = Cpanel::AdminBin::Call::call('PrimaryDomain', 'PrimaryDomain', 'AdminGetDNSZones', { "user" => $Cpanel::user, "old_primary_domain" => $old_primary_domain, "new_primary_domain" => $new_primary_domain});
    my $old_primary_domain_zone = @primary_domain_zone_output[0];
    my $new_primary_domain_zone = @primary_domain_zone_output[1];
    
    my %output_hash;
    my @test1 = $old_primary_domain_zone->{data}->{zone}[0]->{record};


    for my $item (@test1) {
        for my $item1 (@{$item}) {
            while (my ($key, $value) = each %{$item1}) {
                if ($key eq "type") {
                    $output_hash{$key} = $value;
                    #$output = "$output $key = $value | ";
                }
            }
        }
    }
            #Slash_And_Or_Dashes99

    $result->data({"output" => %output_hash, "returns" => $old_primary_domain_zone->{data}->{zone}[0]->{record}});

    return 1;
}

1;