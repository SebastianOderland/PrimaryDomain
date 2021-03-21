package Cpanel::API::ChangePrimaryDomain;

use strict;
use warnings;
use JSON;

use Cpanel::AdminBin::Call;

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
    my $current_primary_domain = %Cpanel::CPDATA{DNS};

    if ($new_primary_domain eq $current_primary_domain) {
        $Cpanel::CPERROR{'changeprimarydomain'} = "Current and new primary domain are the same!";
        return;
    }
    


    my $command_output = Cpanel::AdminBin::Call::call('ChangePrimaryDomain', 'ChangePrimaryDomain', 'AdminChangePrimaryDomain', { "user" => $Cpanel::user, "new_primary_domain" => $new_primary_domain});
    my $returns = $command_output;
    $result->data($returns);

    return 1;
}

1;