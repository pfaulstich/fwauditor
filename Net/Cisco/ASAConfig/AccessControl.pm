package Net::Cisco::ASAConfig::AccessControl;

use 5.006;
use strict;
use warnings;

=head1 NAME

Net::Cisco::ASAConfig::AccessControl

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

An AccessControl object represents a single access control in a Cisco ACL
(plus the preceding comments, aka remarks)

Quick summary of what the module does.

Perhaps a little code snippet.

    use Net::Cisco::ASAConfig::AccessControl;

    my $foo = Net::Cisco::ASAConfig::AccessControl->new();
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

    perldoc Net::Cisco::ASAConfig::AccessControl


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
    # creates new FWAccessControl object
    # takes two arguments: the name of the ACL, and the remainder of the line after the ACL name 
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
    my $acl_name = shift;
    my $def = shift;
    
    $self->{ACL_NAME} = $acl_name;
    $self->{REMARKS} = [];       # A pointer to an array of the remark lines. 
    $self->{CONTROL} = "";       # A string with the access control definition
    $self->{ACTIVE} = 1;         # 0/1 for inactive/active
    $self->{PERMIT_DENY} = "";   # A string indicating permit/deny
    $self->{OBJECT_GROUPS} = []; # A pointer to an array that lists the object groups
    $self->{HOSTS} = [];         # A pointer to an array that lists the hosts
    # add these later if I am so inclined
   # $self->{SERVICES} = [];      # A pointer to an array of the services
   # $self->{SOURCES} = [];       # A pointer to an array of the sources
   # $self->{DESTINATIONS} = [];  # A pointer to an array of the destinations

    
    $self->addInfo($def); # go forth and populate these fields
    
    return $self;
}

sub getACLName {
    my $self = shift;
    return $self->{ACL_NAME};
}

sub getRemarks {
    my $self = shift;
    my $remarks = join ("\n", @{$self->{REMARKS}});
    return $remarks;
}

sub getControl {
    my $self = shift;
    my $control = $self->{CONTROL};
    return $control;
}

sub getEnabled {  # use getEnabled rather than getActive b/c ASDM uses "enabled"
    my $self = shift;
    return $self->{ACTIVE};
}

sub getObjectGroups {
    my $self = shift;
    return @{$self->{OBJECT_GROUPS}};
}

sub getHosts {
    my $self = shift;
    return @{$self->{HOSTS}};
}

sub getFullName {
    # won't be meaningful (unique) until we've gotten the control info
    my $self = shift;
    return $self->{ACL_NAME} . " " . $self->{CONTROL};
}

sub addInfo {
    my $self=shift;
    my $line = shift;

    if ($line =~ /\s*remark (.*)/i) {
        # this is a remark
        push @{$self->{REMARKS}}, $1;
    } elsif ($line =~ /\s*extended/i) {
        # this is the actual access control.
        $self->{CONTROL} = $line;
        # now try to parse this baby!
        $self->parseAccessControl($line);
    } else {
        die "unrecognized access-list command: $line";
    }
        
}

sub parseAccessControl {
    # attempt to parse an access control
    my $self = shift;
    my $line = shift;
 
     if ($line =~ /^extended permit/) {  
         $self->{PERMIT_DENY} = "PERMIT";
     } elsif ($line =~ /^extended deny/) {  
         $self->{PERMIT_DENY} = "DENY";
     } else {
        die "unrecognized permit/deny option: $line";
     }

    if ($line =~ /\binactive\b/) {  # match the lone word inactive
        $self->{ACTIVE} = 0;
    }
    
    # get the object groups
    my @object_groups = ($line =~ /object-group \s+ ([A-Za-z0-9.+_-]*)/gx);  
    $self->{OBJECT_GROUPS} = \@object_groups;
    
    # get the hosts
    my @hosts = ($line =~ /host \s+ ([A-Za-z0-9.+_-]*)/gx);  
    $self->{HOSTS} = \@hosts;
    
    
}

1; # End of Net::Cisco::ASAConfig::AccessControl
