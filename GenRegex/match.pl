#!/usr/bin/perl

use Location;

use strict;
use warnings;


unless (caller) {
    main();
}

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
        # Store the match before we go screwing with the input string
        my $matchedString = $1;

        # Record the start and end of the match relative to the original input string
        my $start = $-[0] + $totalOffset;
        my $end = $start + length($1) - 1;

        # Increment the relative offset by the matched string
        $totalOffset += ($-[0] + length($1));
        
        # Now trim off the match
        $input = substr ($input, $-[0] + length ($1));
        
        # Record the match position (relative to the original string of course)
        $matchedLocations{$start} = Location->new($name, $regex, $matchedString, $start, $end);
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
        print "Next match type: $nextMatchType\n";
        foreach my $nextMatchRegex (@{$mappings->{$nextMatchType}}) { 
            my %nextLocations = findPatternMatches($input, $nextMatchType, $nextMatchRegex);
            %matchedLocations = mergeHash (%matchedLocations, %nextLocations);
        }
    }

    return %matchedLocations;
}

sub locationSortComparator ($$) {
    my ($a, $b) = @_;

    # This is not perfect by any means -- sort by the length of the regular expression
    #  This is so things like 'char' matches of "a" are before 'word' matches of "a"
    my $regexComparison = length($a->getRegex()) - length($b->getRegex());
    if ($regexComparison != 0) {
        return $regexComparison;
    }

    # Sort by position next
    my $positionComparison = $a->getStart() - $b->getStart();
    if ($positionComparison != 0) {
        return $positionComparison;
    }
    
    # And by the size of the match
    my $sizeComparison = length($a->getMatch()) - length($b->getMatch());
    if ($sizeComparison != 0) {
        return $sizeComparison;
    }

    return $sizeComparison;
}


sub flattenMatchedLocations (\%) {
    my ($matchedLocations) = @_;

    my @flattenedLocations = ();

    foreach my $key (keys %$matchedLocations) {
        foreach my $location (@{$matchedLocations->{$key}}) {
            push(@flattenedLocations, $location);
        }
    }

    # And sort
    return sort locationSortComparator @flattenedLocations;
}



sub sortHashArray {
    my (%hash) = @_;

    print "--------------------------------------\n";
    print join (' ', sort {$a <=> $b} keys %hash) . "\n";

    printLocationHash(\%hash);

    foreach my $key (keys %hash) {
        print "Key: $key" . "\n";
        # Sort the array by size of match
        $hash{$key} = sort {length($a->getMatch()) <=> length($b->getMatch())} @{$hash{$key}};
    }

    printLocationHash(\%hash);


    return %hash;
}

sub printLocationHash (\%) {
    my ($hash) = @_;

    foreach my $key (sort { $a <=> $b } keys %$hash) {
        print "$key:\n";
        foreach my $location (@{$hash->{$key}}) {
            print "   " . $location->toString () . "\n";
        }
    }

}


sub main {
    my $testCase1 = "This is a test";

    my %mappings = ();

    $mappings{'word'} = [ "([a-z]+)" ];
    #$mappings{'char'} = [ "([a-z])" ];
    #$mappings{'int'} = [ "([0-9]+)" ];
    #$mappings{'mmyydd'} = 

    # Hash{start of match} = [ Location Location Location ... ]
    my %matchedLocations = findMatches ($testCase1, %mappings);

    # Simulated selections
#    my @userSelections = [ 


    printLocationHash (%matchedLocations);
  


    my @selectedLocations = ();
    push (@selectedLocations, $matchedLocations{0}[0]);
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

    
    # %matchedLocations = sortHashArray(%matchedLocations);
    
    my @finalLocations = flattenMatchedLocations(%matchedLocations);

    my $i = 0;
    foreach my $location (@finalLocations) {
        print "$i: " . $location->toString() . "\n";
        $i++;
    }

    # How would user select?  essentially &x=7&y=3 ?? 
    #                         Or maybe &7,3 -- Keep it simple




}
