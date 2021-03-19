package Cpanel::Admin::Modules::PrimaryDomain::PrimaryDomain;

use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;
use JSON;

use parent 'Cpanel::Admin::Base';

use constant _actions => (
    'AdminChangePrimaryDomain',
);

sub AdminChangePrimaryDomain {
    my $class = shift;

    my $self = {
        _args => shift,
    };

    #my $user = Dumper $self->{_user};

    #my $user = CORE::dump($self->{_user});

    #print "TEST";
    my $user = $self->{_args}{user};
    my $new_primary_domain = $self->{_args}{new_primary_domain};


    #my $command1 = "whmapi1 accountsummary user=" . $user;
    my $command2 = "whmapi1 modifyacct user=" . $user . " DNS=" . $new_primary_domain;


    my $output = `$command2`;
    #my $output = $new_primary_domain . $user;

    return $output;
}

1;