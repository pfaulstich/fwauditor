package Net::Cisco::ASAConfig::NameSet;

use 5.006;
use strict;
use warnings;
# looks like I don't need the following use.  TODO: remove & test
use Net::Cisco::ASAConfig::Name;

=head1 NAME

Net::Cisco::ASAConfig::NameSet

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Net::Cisco::ASAConfig::NameSet;

    my $foo = Net::Cisco::ASAConfig::NameSet->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Paul Faulstich, C<< <perl at sennovation.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-cisco-asaconfig-accesscontrol at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Cisco-ASAConfig-AccessControl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Cisco::ASAConfig::NameSet


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Cisco-ASAConfig-AccessControl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Cisco-ASAConfig-AccessControl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Cisco-ASAConfig-AccessControl>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Cisco-ASAConfig-AccessControl/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Paul Faulstich.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

sub new {
    # creates new FWNameList object, which contains all the name objects
    # takes one argument: the name of the list 
    my $class = shift;
    my $self = {};
    bless $self, $class;
    
    #parse out the rest of the line
    my $name = shift;
    
    $self->{LIST}={};   # object group name -> object group
    
    return $self;
}

sub add {
    my $self = shift;
    my $nameObject = shift;
    my @warnings;
    
    my $name = $nameObject->getName();
    my $ip = $nameObject->getIP();
    
    # check to see if entries already exist
    if ($self->{LIST_BY_NAME}->{$name}) {
        push (@warnings, "Name Duplication", "Name $name is given multiple ip's");
    }
    if ($self->{LIST_BY_IP}->{$ip}) {
        push (@warnings, "Name Duplication", "IP $ip is given multiple names");
    }
    
    $self->{LIST_BY_NAME}->{$name} = $nameObject;   
    $self->{LIST_BY_IP}->{$ip} = $nameObject;   
    
    return @warnings;
}

sub notifyOfUse {
    # notify an object group in the list that there is an access control that uses it
    my $self = shift;
    my $nameOrIP = shift;
    my $accessControlName = shift;
    my @warnings;
    
    # determine if we got a name or IP and get the corresponding object
    # TODO: how to handle if the IP doesn't have a name
    my $nameObject;
    if ($nameOrIP =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
        if (defined $self->{LIST_BY_IP}->{$nameOrIP}) {
            $nameObject = $self->{LIST_BY_IP}->{$nameOrIP};
        } else { # this will be common
            push (@warnings, "IP/Name Validation", "$nameOrIP\t[used in $accessControlName] is not defined with a name");
        }
    } else {
        if (defined $self->{LIST_BY_NAME}->{$nameOrIP}) {
            $nameObject = $self->{LIST_BY_NAME}->{$nameOrIP};
        } else { # this should never happen
            push (@warnings, "IP/Name Validation", "$nameOrIP\t[used in $accessControlName] is not defined with a name");
        }
    }
    if ($nameObject) {
        $nameObject->setWhereUsed($accessControlName);
    }
    return @warnings;
}

sub getIPList {
    my $self = shift;
    return $self->{LIST_BY_IP};
}

sub getNameList {
    my $self = shift;
    return $self->{LIST_BY_NAME};
}

1; # End of Net::Cisco::ASAConfig::NameSet
