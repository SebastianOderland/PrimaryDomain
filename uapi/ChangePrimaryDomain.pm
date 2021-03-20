package Cpanel::API::ChangePrimaryDomain;

use strict;
use warnings;


sub change_primary_domain {
    my ( $args, $result ) = @_;

    my @wanted    = $args->get_multiple('name');
    my $variables = {
        %Cpanel::CPDATA,
        %Cpanel::USERDATA,
        cpanel_root_directory => $Cpanel::CONF{root},
    };

    my $returns = @wanted[0];
    $result->data($returns);

    return 1;
}

1;