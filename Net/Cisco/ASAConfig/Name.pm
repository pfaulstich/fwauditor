package Net::Cisco::ASAConfig::Name;

use 5.006;
use strict;
use warnings;

=head1 NAME

Net::Cisco::ASAConfig::Name 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Net::Cisco::ASAConfig::Name;

    my $foo = Net::Cisco::ASAConfig::Name->new();
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

    perldoc Net::Cisco::ASAConfig::Name


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
    # creates new FWName object, which models Cisco's name
    # takes one argument: the remainder of the line after the word name 
    # expecting "<ip_address> <name> [description <description>]"
    my $class = shift;
    my $self = {};
    bless $self, $class;
    
    #parse out the rest of the line
    my $args = shift;
    
    # first, split the IP and name from the description, if it exists
    my ($firstItems, $description) = split(" description ", $args);
    # now split the first items
    my @items = split (/\s+/, $firstItems);
    $self->{IP} = $items[0];
    $self->{NAME} = $items[1];
    $self->{DESCRIPTION} = $description;
    $self->{WHEREUSED} = [];                    # a pointer to an array w/ everywhere used
    
    return $self;
}

sub getIP {
    my $self = shift;
    return $self->{IP};
}

sub getName {
    my $self = shift;
    return $self->{NAME};
}

sub getDescription {
    my $self = shift;
    return $self->{DESCRIPTION};    
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
    

sub validate {
    my $self=shift;
    my @warnings;
	my $validNameCount;
	my $validAliasCount;
	my $hostName = "";
	my $scrubbedHostName = "";
	my $scrubbedName = "";
	my $hostIP = "";

	my $name = $self->{NAME};
    my $ip = $self->{IP};
    
    # look up the IP using nslookup & do a sanity check
    my $result = `nslookup $ip 2>&1`;  # would be good to do something safer than backticks, since $ip comes from a file
    my ($dnsName, $dnsIP) = ($result =~ /Server:\s+(\S+)\nAddress:\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/);
    ($hostName, $hostIP) = ($result =~ /Name:\s+(\S+)\nAddress:\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/);
    my $nonAuthoritative = ($result =~ /Non-authoritative/);
    my $cantFind = ($result =~ /can't find/);
    my $timedOut = ($result =~ /Request to .* timed-out/);
        
    # get a copy of hostName & name w/out special characters
    $scrubbedHostName = $hostName;
    $scrubbedName = $name;
	if ($scrubbedHostName) {
	    $scrubbedHostName =~ s/[^a-zA-Z0-9.]//g;  #remove all non-alphanumeric characters
	}
	if ($scrubbedName) {
	    $scrubbedName =~ s/[^a-zA-Z0-9.]//g;      #remove all non-alphanumeric characters
	}
        
    # sanity checks:
    # check for ip not found
    if ($cantFind or $timedOut or ($hostIP eq "")) {
        # warn, unless this obviously is a network (*.0)
        unless ($ip =~ /\.0$/) {
            push (@warnings, "IP/Name Validation", "$ip\t[$name] was not found with dnslookup using $dnsName ($dnsIP)");
        }
    } else {
        # sanity checks if we do find the IP
        # check for non-authoritative name server
        if ($nonAuthoritative) {
            push (@warnings, "IP/Name Validation", "$ip\t[$name] was found from a non-authoritative DNS: $dnsName ($dnsIP)");
        }       

        # check that name matches DNS lookup - or is close
        if ( (lc($hostName) eq lc($name)) 
          or (lc($hostName) eq lc("$name.llbean.com")) 
          ) {
            # 100% match. okay! do nothing
            $validNameCount++;
            my $no_op = 1; # this is just here as a breakpoint for debugging
        } elsif (   ($hostName =~ /$name/i) 
           or ($name =~ /$hostName/i)
           or ($scrubbedHostName =~ /$scrubbedName/i)
           or ($scrubbedName =~ /$scrubbedHostName/i)
           ) {
            # hostname contains name or name contains hostname: might be okay.  Issue gentle warning
            #push (@warnings, "IP/Name Validation", "$ip\t[$name] resolves in dns to $hostName ($hostIP) via DNS $dnsName ($dnsIP)");        
            push (@warnings, "IP/Name Validation", "$ip\t[$name] resolves in dns to $hostName ($hostIP)");        
        } else {
            #okay, so we're not even close. Before giving up, check for aliases
            my $result = `nslookup $name 2>&1`; # BAD!!! Replace w/ argv or something safer!
			$result = "" unless (defined($result));
            my ($aliasName, $aliasIP) = ($result =~ /Name:\s+(\S+)\nAddress:\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/);
			# initialize those if they are still undef
			$aliasName = "" unless (defined($aliasName));
			$aliasIP = "" unless (defined($aliasIP));
            if ($ip eq $aliasIP) {
                # okay, this must be an alias.  do nothing
                $validAliasCount++;
                my $no_op = 1; # this is just here as a breakpoint for debugging
            } else {
                # Nothing worked. Do a "fuzzy compare" - also known as the "Levenstein distance" and report how far off we are
                # see 
                # http://www.merriampark.com/ld.htm
                # http://cpan.uwinnipeg.ca/htdocs/Text-Levenshtein/Text/Levenshtein.html
                # http://coding.derkeiler.com/Archive/Perl/perl.beginners/2004-03/1099.html
                # http://www.perlmonks.org/index.pl?node_id=162038
                # http://www.perlmonks.org/index.pl?node=Levenshtein%20distance%3A%20calculating%20similarity%20of%20strings
                # 
                # we'll report the smaller of these two differences:
                #   $hostName (from DNS), $name (from firewall rule)
#                my ($d1, $d2) = distance (lc($hostName), lc($name), lc("$name.llbean.com"));
#                my $distance = ($d1 < $d2) ? $d1 : $d2;
                # convert the distance to a percentage of the length of the reference value
                # eg four & foo have a distance of 2, % = 50%
                # eg four & bar have a distance of 3, % = 75%
                # eg four & bat have a distance of 4, % = 100%
                #remove the percentage.  Seems to be bogus.
                #my $percentage = sprintf("%.0f",$distance/length($hostName)*100); #calculate the distance, and round to an integer
                #push (@warnings, "Name DNS Lookup", "$percentage% likely name violation: $name ($ip) resolves to $hostName ($hostIP) via DNS $dnsName ($dnsIP) (Levenstein distance: $distance)");   
                #skip the distance.  not particularly useful
                #push (@warnings, "Name DNS Lookup", "Likely name violation: $name ($ip) resolves to $hostName ($hostIP) via DNS $dnsName ($dnsIP) (Levenstein distance: $distance)");        
                #push (@warnings, "IP/Name Validation", "$ip\t[$name] resolves in dns to $hostName ($hostIP) via DNS $dnsName ($dnsIP)");        
                push (@warnings, "IP/Name Validation", "$ip\t[$name] resolves in dns to $hostName ($hostIP)");        
            }
        }
    }
    # ping test
    my $pingResult = `ping -n 1 $ip`;
    my ($ping_fail) = ($pingResult =~ /Lost = 1 \(100% loss\)/);
    if ($ping_fail) {
		$ip = "" unless (defined($ip));
		$hostName = "" unless (defined($hostName));
        push (@warnings, "IP/Name Validation", "$ip\t($hostName) failed to respond to ping");
    }
    
    return @warnings;

}



1; # End of Net::Cisco::ASAConfig::Name
