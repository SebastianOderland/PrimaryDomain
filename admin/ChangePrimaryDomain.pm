package Cpanel::Admin::Modules::UpdatePrimaryDomain::UpdatePrimaryDomain;

use strict;
use warnings;

use parent 'Cpanel::Admin::Base';

use constant _actions => (
    'SAY_HI',
    'GET_INFO',
);

sub SAY_HI {
    return 'hello';
}

sub GET_INFO {
    my ($self, @args) = @_;

    return (
        \@args,
        $self->get_cpuser_domains(),
        $self->get_caller_username(),
    );
}

1;