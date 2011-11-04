package Net::Cisco::ASAConfig::AccessControlSet;

use 5.006;
use strict;
use warnings;
use Net::Cisco::ASAConfig::AccessControl;


=head1 NAME

Net::Cisco::ASAConfig::AccessControlSet

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Net::Cisco::ASAConfig::AccessControlSet;

    my $foo = Net::Cisco::ASAConfig::AccessControlSet->new();
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

    perldoc Net::Cisco::ASAConfig::AccessControlSet


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
    # creates new AccessList object, which models Cisco's access-list
    # takes two argument: the name, and the remainder of the line after the name 
    # expecting for the second arg:
    #   - "remark <comment>"
    #   - "extended permit object-group TCPUDP object-group DNS_LookUppers object-group DNSservers object-group DNSudp_tcp 
    #   - "extended permit udp 10.100.110.0 255.255.255.0 object-group ntpGroup object-group TimeSyncSources object-group ntpGroup 
    #   - "extended permit tcp object-group XtranetWebServers object-group NetegrityServers object-group NetegProts 
    #   - "extended permit tcp host 10.100.110.16 object-group NetegrityServers object-group NetegProts 
    my $class = shift;
    my $self = {};
    bless $self, $class;
    
    #parse out the rest of the line
    my $name = shift;
    my $def = shift;
    
    $self->{NAME}=$name;
    $self->{CURRENT_AC};   # keep track of the current access control as we parse through the list
    $self->{LIST} = {};  
    #$self->{FULL_LIST} = [];  # a list of each access control line
    $self->handleAccessControl($def);
    
    return $self;
}

sub getName {
    my $self = shift;
    return $self->{NAME};
}

sub getCurrentControl {
    my $self = shift;
    return $self->{CURRENT_AC};
}

sub handleAccessControl {
    my $self=shift;
    my $def = shift;

        if (! $self->{CURRENT_AC}) {
            # new access control
            $self->{CURRENT_AC} = AccessControl->new($self->getName(), $def);
        }

        elsif ($def =~ /^remark/) {
            # if the current access control has a control defined (it isn't just remarks), 
            # then this is a new control
            # otherwise, this is just another remark in the existing access control.
            if ($self->{CURRENT_AC}->getControl()) {
                # new control
                $self->{CURRENT_AC} = AccessControl->new($self->getName(), $def);
            } else {
                # just another remark
                $self->{CURRENT_AC}->addInfo($def);
            }
            
        } elsif ($def =~ /^extended/) {
            $self->{CURRENT_AC}->addInfo($def);
            # we don't actually add the control to the list until now
            $self->{LIST}->{$def} = $self->{CURRENT_AC};
        } else {
            die "unrecognized access-list command: $args";
        }

}

sub add {
    my $self = shift;
    my $def = shift;
    
    #push @{$self->{FULL_LIST}}, $def;
    $self->handleAccessControl($def);
    
}


1; # End of Net::Cisco::ASAConfig::AccessControlSet
