#!/usr/bin/perl

use strict;
use warnings;

my @inputs = ("This is a test", "I also want to match this", "And this too");

my $regEx1 = ".*";
my $regEx2 = "\\d*";
my $regEx3 = "[\\w\\s]+";

if ("This is a test" =~ /^\d*$/) {
    print "match?";
}

print computeFitness($regEx1, @inputs) . "\n";
print computeFitness($regEx2, @inputs) . "\n";
print computeFitness($regEx3, @inputs) . "\n";

sub computeFitness {
    my ($regEx, @inputs) = @_;

    foreach (@inputs) {
        if (/^$regEx$/) {
            print "Match: $regEx";
        }
    }
}
