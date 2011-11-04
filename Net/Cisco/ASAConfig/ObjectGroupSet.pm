package Net::Cisco::ASAConfig::ObjectGroupSet;

use 5.006;
use strict;
use warnings;
# not sure this include is needed. TODO: remove and test
use Net::Cisco::ASAConfig::ObjectGroup;


=head1 NAME

Net::Cisco::ASAConfig::ObjectGroupSet - The great new Net::Cisco::ASAConfig::ObjectGroupSet!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Net::Cisco::ASAConfig::ObjectGroupSet;

    my $foo = Net::Cisco::ASAConfig::ObjectGroupSet->new();
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

    perldoc Net::Cisco::ASAConfig::ObjectGroupSet


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
    # creates new FWObjectGroupList object, which contains all the object groups
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
    my $objectGroup = shift;
    
    my $objectGroupName = $objectGroup->getName();
    
    $self->{LIST}->{$objectGroupName} = $objectGroup;   
}

sub notifyOfUse {
    # notify an object group in the list that there is an access control that uses it
    my $self = shift;
    my $objectGroupName = shift;
    my $accessControlName = shift;
    if ($self->{LIST}->{$objectGroupName}) {
        $self->{LIST}->{$objectGroupName}->setWhereUsed($accessControlName);
    } else {
        warn ("Attempted to setWhereUsed($accessControlName) to $objectGroupName, but $objectGroupName not in this FWObjectGroupList. Software debugging hint: check FWAccessControl.pm::parseAccessControl to make sure that all characters in this group name are matched when defining objectGroups.");
    }
}

sub getList {
    my $self = shift;
    return $self->{LIST};
}

1; # End of Net::Cisco::ASAConfig::ObjectGroupSet
