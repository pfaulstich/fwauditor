package Net::Cisco::ASAConfig::ObjectGroup;

use 5.006;
use strict;
use warnings;

=head1 NAME

Net::Cisco::ASAConfig::ObjectGroup 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Net::Cisco::ASAConfig::ObjectGroup;

    my $foo = Net::Cisco::ASAConfig::ObjectGroup->new();
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

    perldoc Net::Cisco::ASAConfig::ObjectGroup


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
    # creates new FWObjectGroup object, which models Cisco's object-group
    # takes one argument: the remainder of the line after the word object-group 
    # expecting "network <network_name>" or "service <service_name> <protocol>"
    my $class = shift;
    my $self = {};
    bless $self, $class;
    
    #parse out the rest of the line
    my $args = shift;
    my @items = split (/\s+/, $args);
    #$self->{NAME} = $args;
    $self->{TYPE} = $items[0];
    #$self->{TYPE_NAME} = $items[1];
    $self->{NAME} = $items[1];
    $self->{WHEREUSED} = [];                    # a pointer to an array w/ everywhere used
    $self->{GROUPS} = [];                       # a pointer to an array w/ other groups this group contains
    
    # types
    if (lc($self->{TYPE}) eq "network") {
        $self->{NETWORK_OBJECTS_NETWORKS} = []; # each entry is a pointer to an array
        $self->{NETWORK_OBJECTS_HOSTS} = ();    # each entry is a real array
    } elsif (lc($self->{TYPE}) eq "service") {
         $self->{SERVICE_PROTOCOL} = $items[2];
         $self->{PORTS} = [];
         $self->{PORT_RANGES} = [];
   }
    return $self;
}

sub getName {
    my $self = shift;
    return $self->{NAME};
}

sub getType {
    my $self = shift;
    return $self->{TYPE};
}


sub setDescription {
    my $self = shift;
    my $desc = shift;
    $self->{DESCRIPTION} = $desc; 
    return $self->{DESCRIPTION};    
}

sub getDescription {
    my $self = shift;
    return $self->{DESCRIPTION};    
}

sub setNetworkObject {
    # takes one argument: the remainder of the line after the word network-object 
    # expecting "host <host_ip)>" or "<network_ip> <network_mask>"
    # returns a hash with some or all of the values:
    #   host  => hostname
    #   ip    => ip
    #   mask  => network mask
    #   alias => alias name
    my $self = shift;
    my $args = shift;
    my @items = split(/\s+/, $args);
    my %results;
    
    if ($items[0] eq "host") {
        push @{$self->{NETWORK_OBJECTS_HOSTS}}, $items[1];
        $results{host} = $items[1];

    } elsif (looksLikeIP($items[0]) and looksLikeIP($items[1])) {
        # ip & nw mask
        push @{$self->{NETWORK_OBJECTS_NETWORKS}}, [$items[0], $items[1]];
        $results{ip}   = $items[0];
        $results{mask} = $items[1];
        
    } elsif (looksLikeIP($items[1])) {
        # alias name & nw mask
        # TODO: lookup to confirm alias exists.  But that would require access to the %names hash
        # from fwauditor - should make that a controller object that this can call.  major change
        # for now, assume fw enforces that and just take the item
        push @{$self->{NETWORK_OBJECTS_NETWORKS}}, [$items[0], $items[1]];
        $results{alias} = $items[0];
        $results{mask}  = $items[1];
        
    } else {
        die "Unknown network-object: $args";
    }
    
    return %results;
}

sub getNetworkHostObjects {
    return @{$self->{NETWORK_OBJECTS_HOSTS}};
}

sub getNetworkNetworkObjects {
    return @{$self->{NETWORK_OBJECTS_NETWORKS}};
}

sub setPortObject {
    # takes one argument: the remainder of the line after the word port-object 
    # expecting "eq <protocol>" or "eq <port#>" or "range <low_port> <high_port>"
    my $self = shift;
    my $args = shift;
    my @items = split(/\s+/, $args);

    if ($items[0] eq "eq") {
#        if ($items[2] =~ /^\d+$/) {
#            # port number
#            push @{$self->{PORT_NUMBERS}}, $items[2];  
#        } elsif ($items[2] =~ /^\w+$/) {
#            # port protocol
#            push @{$self->{PORT_NAMES}}, $items[2];  
#        }
        push @{$self->{PORTS}}, $items[1];  
    } elsif ($items[0] eq "range") {
        push @{$self->{PORTS}}, [$items[1], $items[2]];  
    } else {
        die "Unknown service-object: $args";
    }
}

sub setGroupObject {
    # takes one argument: the remainder of the line after the word group-object 
    # expecting "<group_name>"
    my $self = shift;
    my $arg = shift;  #only this one arg
    push @{$self->{GROUPS}}, $arg; 
}

sub setWhereUsed {
    # takes one argument: the object that uses this
    my $self = shift;
    my $usedIn = shift;
    push @{$self->{WHEREUSED}}, $usedIn;
    # could this fail? how to error handle?
}

sub getWhereUsed {
    # returns a pointer to the array of objects that use this
    my $self = shift;
    return @{$self->{WHEREUSED}};
}
    
sub looksLikeIP {
    # returns true if a value looks like an ip address (#.#.#.#).  # is 0-999, not 0-255.
    # note that this is not a "real" method, so we don't use $self;
    my $item = shift;
    my $looksLikeIP = ($item =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/);
    return $looksLikeIP;
}

sub validate {
    my $self=shift;
    if (lc($self->{TYPE}) eq "network") {
        # lookup the names for any single-host IP's
    } elsif (lc($self->{TYPE}) eq "service") {
    } else {
        die "Cannot validate type: $self->{TYPE}";
    }
}




1; # End of Net::Cisco::ASAConfig::ObjectGroup
