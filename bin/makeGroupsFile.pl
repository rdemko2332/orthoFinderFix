#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;

=pod

=head1 Description

Take the core groups file from the core workflow, and integrate peripheral sequences after they have been assigned to groups.

=head1 Input Parameters

=over 4

=item coreGroup

The groups file generated from the core workflow

=back

=over 4

=item peripheralGroup

Input file holding peripheral sequences and their group assignments

=back

=cut

my ($coreGroup,$peripheralGroup,$output);

&GetOptions("coreGroup=s"=> \$coreGroup,
	    "peripheralGroup=s"=> \$peripheralGroup,
            "output=s"=> \$output);

open(my $core, '<', $coreGroup) || die "Could not open file $coreGroup: $!";
open(my $peripheral, '<', $peripheralGroup) || die "Could not open file $peripheralGroup: $!";
open(OUT,">$output");

my %groupSeqs;

# For each Peripheral Assignment
while (my $line = <$peripheral>) {
    chomp $line;
    my @sequenceAssignment = split(/\t/, $line);
    # Get the sequence
    my $sequence = $sequenceAssignment[0];
    # Get the group assignment
    my $groupId = $sequenceAssignment[1];

    # If group hash array exists, add sequence to group array
    if ($groupSeqs{$groupId}) {
        push( @{$groupSeqs{$groupId}}, $sequence);
    }
    # Else create group hash array and add sequence
    else {
	$groupSeqs{$groupId} = ();
        push( @{$groupSeqs{$groupId}}, "$sequence");
    }
}

close $peripheral;

# For each core group
while (my $line = <$core>) {
    chomp $line;
    if ($line =~ /^(OG\d+_\d+):\s(.+)/) {
	# Get the groupID
	my $groupId = $1;
	# Get the group sequences
	my $sequences = $2;
	# Create array of sequences
	my @coreSequences = split(/\s/, $sequences);

	my $groupSeqsString;

	# If peripheral sequences have been assigned this group
	if ($groupSeqs{$groupId}) {
	    # Get the peripheral sequences assigned to this group
            my @peripheralSequences = @{$groupSeqs{$groupId}};
	    # Combine the core and peripheral sequences
	    my @allGroupSeqs = (@coreSequences,@peripheralSequences);
	     $groupSeqsString = join(' ', @allGroupSeqs);
	}

	# If no peripheral sequences have been assigned this group
        else {
	    $groupSeqsString = join(' ', @coreSequences);
	}

	# Print out groupId and all sequences assigned to this group
	print OUT "$groupId: $groupSeqsString\n";

    }

    else {
        die "Improper groupFile format\n$line\n";
    }   

}	

close $core;
close OUT;
