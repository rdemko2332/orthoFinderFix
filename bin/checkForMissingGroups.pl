#!/usr/bin/perl

use strict;
use warnings;

# Input species ID file
my $inputDir = $ARGV[0];
my $buildVersion = $ARGV[1];

open(OUT,">missingGroups.txt");

my $groupPrefix = "OG${buildVersion}_";
my $currentGroupInt = 0;

my $currentGroupFile = &reformatGroup($currentGroupInt, $groupPrefix);

my @files = <$inputDir/*.sim>;
foreach my $file (@files) {
    until ($currentGroupFile eq $file) {
	$currentGroupFile =~ s/\.\///g;
	$currentGroupFile =~ s/\.sim//g;
        print OUT "$currentGroupFile\n";
	$currentGroupInt += 1;
	$currentGroupFile = &reformatGroup($currentGroupInt,$groupPrefix);
    }
    $currentGroupInt += 1;
    $currentGroupFile = &reformatGroup($currentGroupInt,$groupPrefix);
}

close OUT;

sub reformatGroup {
    my ($groupInt,$groupPrefix) = @_;
    my $reformattedGroupInt = sprintf("%07d", $groupInt);
    my $reformattedGroup = "./${groupPrefix}${reformattedGroupInt}.sim";
    return $reformattedGroup;
}
