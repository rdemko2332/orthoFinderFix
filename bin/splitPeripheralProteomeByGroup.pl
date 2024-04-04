#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Split a proteome into multiple group files using group assignments.

=head1 Input Parameters

=over 4

=item groups

The file containing sequence group assignments.

=back

=over 4

=item proteome

The proteome file you wish to split

=back

=cut

my ($groups,$proteome);

&GetOptions("groups=s"=> \$groups,
	    "proteome=s"=> \$proteome);

open(my $data, '<', $groups) || die "Could not open file $groups: $!";
open(my $pro, '<', $proteome) || die "Could not open file $proteome: $!";

# Make hash to store sequence group assignments
my %seqToGroup;
# For each line in groups file
while (my $line = <$data>) {
    chomp $line;
    my ($seq,$groupId) = split(/\t/, $line);
    # Record the group assignment for each sequence
    $seqToGroup{$seq} = $groupId;
}
close $data;

my $currentGroupId;
while (my $line = <$pro>) {
    chomp $line;

    if ($line =~ /^>(.*)/) {
	my $groupId = $seqToGroup{$1};
	if ($currentGroupId eq $groupId) {
            print OUT "$line\n";
	}
	else {
            close OUT if($currentGroupId);
	    open(OUT,">${groupId}.fasta")  || die "Could not open file ${groupId}.fasta: $!";
	    print OUT "$line\n";
	    $currentGroupId = $groupId;
	}
    }
    else {
        print OUT "$line\n";
    }
}	
close OUT;
