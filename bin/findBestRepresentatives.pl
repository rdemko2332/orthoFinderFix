#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;

=pod

=head1 Description: 

Determine the best representative per group by calculating the lowest average e-value across all sequences within a group.

=head1 Input Parameters

=over 4

=item groupFile 

The pairwise blast results file. Results are split by group within the file.

=back 

=cut

my ($groupFile);

&GetOptions("groupFile=s"=> \$groupFile);

my $QSEQ_COLUMN = 0;
my $EVALUE_COLUMN = 10;

open(my $data, '<', $groupFile) || die "Could not open file $groupFile: $!";

my $group;

my %values;

while (my $line = <$data>) {
    chomp $line;
    next unless($line);

    # Calculate values for the last group
    if($line =~ /==> (\S+).sim <==/) {
        &calculateAverageAndPrintGroup($group, \%values) if($group);
        $group = $1;
        %values = ();
        next;
    }

    # Get array of pairwise blast results
    my @lineAr = split(/\t/, $line);

    # Retrieve query sequence
    my $qseq = $lineAr[$QSEQ_COLUMN];

    # Retrieve evalue
    my $evalue = $lineAr[$EVALUE_COLUMN];

    $values{$qseq}->{sum} += $evalue;
    $values{$qseq}->{total}++;
}

# make sure to do the last group here
&calculateAverageAndPrintGroup($group, \%values) if($group);

1;

=pod

=head1 Subroutines

=over 4

=item calculateAverageAndPrintGroup()

This process takes the group ID and the values object. The values object contains the sum of the total evalues and the number of pairs that involved this sequence that passed the e-value threshold. This process is called once per group. I will run through all of the qseqs in the values object and determine which sequence has the lowest average e-value. This sequence is identified as the best representative for this group.

=back

=cut

sub calculateAverageAndPrintGroup {
    my ($group, $values) = @_;

    my $minValue = 1000000000;

    my $bestRepresentative;

    # For every query sequence
    foreach my $qseq (keys %values) {
        my $avg = $values{$qseq}->{sum} / $values{$qseq}->{total} ;
        if($avg <= $minValue) {
            $bestRepresentative = $qseq;
            $minValue = $avg;
        }
    }


    print "${group}\t${bestRepresentative}\n";
}
