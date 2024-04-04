#!/usr/bin/perl

use strict;
use warnings;

=pod

=head1 Description

Create a new cache directory for peripherals. Remove all blast files that involve an organism that was marked as outdated.

=head1 Input Parameters

=over 4

=item outdated

File holding organism abbrevs of organisms whose proteomes have changed since the last run.

=back

=over 4

=item peripheralCache

The output directory to write the cached blast files.

=back

=cut

my $outdatedFile = $ARGV[0]; # File containing organism abbrev, one per line
my $peripheralCache = $ARGV[1]; # Directory of cache files

# Open Outdated file
open my $fh_outdated, '<', $outdatedFile or die "Cannot open $outdatedFile: $!";
my @outdated;
# Make array object to contain all of the outdated organisms 
while (my $line = <$fh_outdated>) {
    chomp $line;
    if ($line =~ /^(.+)/) {
        my ($outdatedSpecies) = ($1);
        push(@outdated, $outdatedSpecies);
    }
}
close $fh_outdated;

# For each organism that requires and update
foreach my $update (@outdated) {
    # If there is a cache file for the organism, delete it
    if (-e "$peripheralCache/${update}.fasta.out") {
        unlink "$peripheralCache/${update}.fasta.out";
        print "Removed ${update}.fasta.out from cache\n";
    }
}
