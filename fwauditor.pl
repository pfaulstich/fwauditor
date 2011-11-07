#! /usr/bin/perl

# TODO: working, but we lose each multiline item when we move to the next.
# probably should do error checking at end
# build out global lists of all ACLs, names, etc, like I do for object-groups


use strict;
use Getopt::Long qw(:config auto_help auto_version);
use Pod::Usage;
use File::Basename;
#use constant MSWIN => $^O =~ /MSWin32|Windows_NT/i;

use Net::Cisco::ASAConfig::ObjectGroup;
use Net::Cisco::ASAConfig::AccessControlSet;
use Net::Cisco::ASAConfig::ObjectGroupSet;
use Net::Cisco::ASAConfig::Name;
use Net::Cisco::ASAConfig::NameSet;

use constant FILETAG => "audit";

# define a version for this script
$main::VERSION = 0.1;  

# handle cmd line arguments
my $fwFile;
my $outfile;
# default options:
my $ping = 1;
my $nslookup = 1;

my $result = GetOptions (
                "help|?" => sub {pod2usage(-verbose=>2)},
                "ping!" =>  \$ping,
                "nslookup!" =>  \$nslookup
             ) or pod2usage(-verbose=>0);
if (@ARGV == 1) { 
    ($fwFile) = @ARGV;
    
    # split up the file into its path, name, & extension
    # see http://perldoc.perl.org/File/Basename.html
    # added the ? in the regex to only grab the last, eg file.something.txt should just have .txt
    my ($name, $path, $suffix) = fileparse($fwFile, qr/\.[^.]*?/); 
    $outfile = "$path$name." . FILETAG . ".txt";
    
} else {
    pod2usage(-verbose=>0, -msg=>"You must specify one (and only one) file\n"); 
}

# set up the data structures
#my %names;                  # name, ip
#my %namesByIP;              # ip, name
my $names = Net::Cisco::ASAConfig::NameSet->new();                # all the name definitions, by name and IP
my $validNameCount;         # total number of names that match dnslookup
my $validAliasCount;        # total number of aliases that match dnslookup

my $multiLineItem;          # any item that spans multiple lines
#my @objectGroups;           # all the object-group definitions
my $objectGroups = Net::Cisco::ASAConfig::ObjectGroupSet->new();  # all the object-group definitions

# complex data structures
# warningList is a hash of anonymous arrays: (A=>[a1,a2,...], B=>[b1,b2,...],...)
# the keys are types of warningList, the arrays are all the invidual warningList of that type
my %warningList;

# read the file and create our data structures
open (READFILE, "<$fwFile") or die ("Cannot open $fwFile for reading: $^E\n");
my $lineCount = 1;
while (<READFILE>) {
    chomp;
    process($_, $lineCount);
    $lineCount++;
}
close READFILE or die "Failure closing $fwFile: $^E\n";
checkWhereUsed();

#reporting
open (REPORT, ">$outfile") or die ("Cannot open $outfile for writing: $^E\n");
# first print the program settings:
print REPORT "Program Settings:\n";
print REPORT "  Config File: $fwFile\n  NSLookup checks: " . ($nslookup ? "ON" : "OFF") . "\n  Ping checks: " . ($ping ? "ON" : "OFF") . "\n";
foreach my $warnType (keys %warningList) {
    print REPORT "$warnType:\n";
    my $warnListRef = $warningList{$warnType};
    foreach my $msg (sort @$warnListRef) {
        print REPORT "  $msg\n";
    }
}
close REPORT or die "Failure closing $outfile: $^E\n";

END {
    print "Hit enter to close window.";
    <STDIN>;
}



sub process {
    my ($line, $lineCount) = @_;
    # take a line and add it to the appropriate data structure, do basic checks, etc
    
    # check for TODO:
    if ($line =~ /TODO\:(.*)/ ) {
        AddWarning("TODO", "TODO item found on line $lineCount: $1");
    }
    
    #name
    if ($line =~ /^name\s+(.*)/ ) {
        $multiLineItem = "";
        my $item = Net::Cisco::ASAConfig::Name->new($1);
        my @warnings = $names->add($item);
        push @warnings, $item->validate(-ping=>$ping, -nslookup=>$nslookup);
        # step through the warnings and add to %warningList;
        for(my $w==0; $w < @warnings; $w++) {
            AddWarning($warnings[$w], $warnings[++$w]); # warnings contain two parts
        }
    }
    
    # object-group
    if ($line =~ /^object-group\s+(.*)/) {
        $multiLineItem = Net::Cisco::ASAConfig::ObjectGroup->new($1);
        #push @objectGroups, $multiLineItem;
        $objectGroups->add($multiLineItem);
    }
    
    # network-object
    if ($line =~/^\s+network-object\s+(.*)/) {
        # we better have a multiLineItem, or else we're in trouble...
        if ($multiLineItem) {
            # set it to a network object
            my %nwObject = $multiLineItem->setNetworkObject($1);
            # now let our names list know 
            my @warnings;
            if      ($nwObject{"host"} ) { 
                @warnings = $names->notifyOfUse( $nwObject{"host"},  $multiLineItem->getName() );
            } elsif ($nwObject{"ip"}   ) { 
                @warnings = $names->notifyOfUse( $nwObject{"ip"},    $multiLineItem->getName() );
            } elsif ($nwObject{"alias"}) { 
                @warnings = $names->notifyOfUse( $nwObject{"alias"}, $multiLineItem->getName() );
            }
            for(my $w==0; $w < @warnings; $w++) {
                AddWarning($warnings[$w], $warnings[++$w]); # warnings contain two parts
            }
        } else {
            #oops!
        }
    }
    
    # port-object
    if ($line =~/^\s+port-object\s+(.*)/) {
        # we better have a multiLineItem, or else we're in trouble...
        if ($multiLineItem) {
            $multiLineItem->setPortObject($1);
        } else {
            #oops!
        }
    }
    
    # group-object
     if ($line =~/^\s+group-object\s+(.*)/) {
        # we better have a multiLineItem, or else we're in trouble...
        if ($multiLineItem) {
            $multiLineItem->setGroupObject($1);
            # now let our groups list know
            $objectGroups->notifyOfUse( $1, $multiLineItem->getName() );
        } else {
            #oops!
        }
    }
   
    # access-control list
     if ($line =~ /^access-list\s+(\w+)\s+(.*)/) {
        my $name = $1;
        my $def = $2;
        # is this a new ACL or continuing an existing ACL?
        my $newACL;
        if ($multiLineItem and ($multiLineItem=~/^AccessControlSet=HASH/)) {
            # our current multiLineItem is an ACL, so see if it is new
            if ($multiLineItem->getName() ne $name) {
                # yup, new ACL
                $newACL = 1;
            }
        } else {
            #definitely a new ACL
            $newACL = 1;
        }
        
        if ($newACL) {
            # create a new ACL
            $multiLineItem = Net::Cisco::ASAConfig::AccessControlSet->new($name, $def);
        } else {
            # add to an existing one
            $multiLineItem->add($def);
        }
        
        # go get the objects used by the current access control (if any)
        # and tell those objects about the current access control
        my $currentControl=$multiLineItem->getCurrentControl();
        # $currentControl should always be valid, but in case it isn't...
        # TODO: check that currentControl is valid
        foreach my $group ($currentControl->getObjectGroups()) { # what if getCurrentControl is empty? should never be
            $objectGroups->notifyOfUse( $group, $currentControl->getFullName() );
        }
        foreach my $host ($currentControl->getHosts()) { # what if getCurrentControl is empty? should never be
            $names->notifyOfUse( $host, $currentControl->getFullName() );
        }  
        
        # check for Enabled "Enable when needed" rules
        # we check for the Control so we only report this once we have it.
        if ($currentControl->getControl() and $currentControl->getEnabled() and $currentControl->getRemarks() =~ /enable when/i) {
            AddWarning("Enable when needed is enabled", "Line $lineCount: $1, ACL " . $currentControl->getACLName() . ", " . $currentControl->getControl()); 
        }
    }   
    
    
    # http, ssh
    # TODO: add check for unusual interface used for management
    if ($line =~ /^http\s+(.*)/) {
        $multiLineItem = "";
        my $remainder = $1;
        my $ipOrName;
        if ($remainder eq "server enable" ) { # do nothing 
        } elsif ($remainder =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ) { 
            $ipOrName = $1;
        } else {
            $remainder =~ /^([a-zA-Z0-9._-]*)/;
            $ipOrName = $1;
        }
        if ($ipOrName) {
            $names->notifyOfUse( $ipOrName, "http access" );
        }
    }
    if ($line =~ /^ssh\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ) { 
        $multiLineItem = "";
        $names->notifyOfUse( $1, "ssh access" );
    }
    
    # static NAT
    # TODO: add validation
    if ($line =~ /^static\s+\(\w*,\w*\)\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ) { 
        $multiLineItem = "";
        $names->notifyOfUse( $1, "static NAT from" );
        $names->notifyOfUse( $2, "static NAT to" );
    }
    
    # dynamic NAT
    # TODO: add validation
    # nat (inside) 1 mwsvtst2 255.255.255.255
    if ($line =~ /^nat\s+\(\w*\)\s+\d*\s*([A-Za-z0-9_.-]+)\s+\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ ) { 
        $multiLineItem = "";
        $names->notifyOfUse( $1, "dynamic NAT from" );
    }
    
        
    
    
}

sub AddWarning {
    # add an entry to the warning hash
    my ($title, $msg) = @_;
    if ($warningList{$title}) {
        # $warningList{$title} array exists, so add to it
        push @{$warningList{$title}}, $msg;   # @{something} takes something pointer and treats it like an array.  
    } else {
        # $warningList{$title} array does not exist, so create it w/ this msg
        $warningList{$title} = [$msg];
    }
}

    
sub checkWhereUsed {
   # loop through the object groups and names and see where used
   my $objectGroupList = $objectGroups->getList();
   foreach my $objectGroup (values %{$objectGroupList}) {
        my @whereUsed = $objectGroup->getWhereUsed();
        if (@whereUsed == 0) {
            # group isn't used
            my $name = $objectGroup->getName();
            my $type = $objectGroup->getType();
            my $description = $objectGroup->getDescription();
            AddWarning ("Object Groups", "Unused Object Group: Group $name (Type: $type, Description: $description)");
        }
   }
   
# should be a duplicate of name list.  need a way to confirm   
#   my $ipList = $names->getIPList();
#   foreach my $host (values %{$ipList}) {
#        my @whereUsed = $host->getWhereUsed();
#        if (@whereUsed == 0) {
#            # group isn't used
#            my $name = $host->getName();
#            my $ip = $host->getIP();
#            my $description = $host->getDescription();
#            AddWarning ("Names", "Unused Name: Name $name (IP: $ip, Description: $description) is not used");
#        }
#   }

   my $nameList = $names->getNameList();
   foreach my $host (values %{$nameList}) {
        my @whereUsed = $host->getWhereUsed();
        if (@whereUsed == 0) {
            # group isn't used
            my $name = $host->getName();
            my $ip = $host->getIP();
            my $description = $host->getDescription();
            # AddWarning ("Names", "Unused Name: Name $name (IP: $ip, Description: $description)");
            AddWarning ("IP/Name Validation", "$ip\t[$name] not used (Description: $description)");
        }
   }
   
}

