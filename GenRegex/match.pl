#!/usr/bin/perl

use Location;

use strict;
use warnings;


main();

# Merge a hash of values into a hash of array values
sub mergeHash(\%\%) {
    my ($hash1, $hash2) = @_;
   
    foreach my $key (keys %$hash2) {
        push(@{$hash1->{$key}}, $hash2->{$key});
    }

    return %$hash1;
}


sub findPatternMatches {
    my ($input, $name, $regex) = @_;

    # Location matches within the string
    my %matchedLocations = ();

    # Total offset relative to the original input string
    my $totalOffset = 0;
    while ($input =~ m/$regex/ig) {
        # Record the start and end of the match relative to the original input string
        my $start = $-[0] + $totalOffset;
        my $end = $start + length($1) - 1;

        # Increment the relative offset by the matched string
        $totalOffset += ($-[0] + length($1));

        # Now trim off the match
        $input = substr ($input, $-[0] + length ($1));

        # Record the match position (relative to the original string of course)
        $matchedLocations{$start} = Location->new($name, $regex, $start, $end);
    }

    return %matchedLocations;
}

sub buildRegex {
    # Assumes the selected locations are in ascending order
    my (@locations) = @_;
   
    # Outputted regex
    my $regEx;
    
    my $lastEnd = 0;
    foreach my $l (@locations) {
        if ($l->getStart() > $lastEnd) {
            $regEx .= ".*";
        } 
        
        $regEx .= $l->getRegex();

        $lastEnd = $l->getEnd () + 1;
    }

    return $regEx;
}

sub findMatches ($\%) {
    # Inputs: 
    #   input:    String to find matches upon
    #   mappings: Hash map of mappings
    # Returns: Hash{start of match} = [ Location Location Location ... ]
    my ($input, $mappings) = @_;

    my %matchedLocations = ();
    
    # Loop through the different match types
    foreach my $nextMatchType (keys %$mappings) {
        foreach my $nextMatchRegex (@{$mappings->{$nextMatchType}}) { 
            my %nextLocations = findPatternMatches($input, $nextMatchType, $nextMatchRegex);
            %matchedLocations = mergeHash (%matchedLocations, %nextLocations);
        }
    }

    return %matchedLocations;
}



sub main {
    my $testCase1 = "This is a test";

    # Match at 0, 5, 8, 10

    my %mappings = ();

    $mappings{'word'} = [ "([a-z]+)" ];
    $mappings{'char'} = [ "([a-z])" ];

    # Hash{start of match} = [ Location Location Location ... ]
    my %matchedLocations = findMatches ($testCase1, %mappings);


    # Now try and loop through the hash
    foreach my $key (sort { $a <=> $b } keys %matchedLocations) {
        print "$key:\n";
        foreach my $location (@{$matchedLocations{$key}}) {
            print "   " . $location->toString () . "\n";
        }
    }
    
    my @selectedLocations = ();
    push (@selectedLocations, $matchedLocations{0}[1]);
    push (@selectedLocations, $matchedLocations{5}[0]);
    push (@selectedLocations, $matchedLocations{8}[0]);
    push (@selectedLocations, $matchedLocations{10}[0]);

    my $regEx = buildRegex (@selectedLocations);

    print $regEx . "\n";

    if ($testCase1 =~ m/$regEx/ig) {
        print "Num matches: " . scalar @- . "\n";
        print "Success!\n";

        foreach my $match (@-) {
            print "$match\n";
        }
    }

}
