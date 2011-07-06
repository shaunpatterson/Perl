#!/usr/bin/perl

use Location;

use strict;
use warnings;


unless (caller) {
    main();
}

sub findPatternMatches {
    my ($input, $name, $regex) = @_;

    # Location matches within the string
    my @matchedLocations = ();

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
        
        # Record the match 
        push (@matchedLocations, Location->new($name, $regex, $matchedString, $start, $end));

        # Record the match position (relative to the original string of course)
        #$matchedLocations{$start} 
    }

    return @matchedLocations;
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


sub locationSortComparator ($$) {
    my ($a, $b) = @_;

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

sub findMatches ($\@) {
    # Inputs: 
    #   input:    String to find matches upon
    #   mappings: List of hash maps of mappings
    # Returns: Ordered list of match locations
    my ($input, $mappingsList) = @_;

    my @matchedLocations = ();
    
    foreach my $nextMappingHash (@$mappingsList) {
        # Loop through the different match types

        # Matched locations for the next mapping type
        my @nextMatchedLocations = ();

        foreach my $nextMatchType (keys %$nextMappingHash) {
            foreach my $nextMatchRegex (@{$nextMappingHash->{$nextMatchType}}) { 
                @nextMatchedLocations = (@nextMatchedLocations, findPatternMatches ($input, $nextMatchType, $nextMatchRegex));    
            }
        }

        # Sort the next matched locations by starting position
        @nextMatchedLocations = sort locationSortComparator @nextMatchedLocations;


        # Record all the matched for the mapping
        @matchedLocations = (@matchedLocations, @nextMatchedLocations);
    }

    return @matchedLocations;
}


sub main {
    my $testCase1 = "This is a test";

    # Encode the mapping precedence by offset within a matching array
    my @mappingsList = (
                            { "char" => [ "([a-z])"  ] },
                            { "word" => [ "([a-z]+)" ] },
                            { "int"  => [ "([0-9]+)" ] },
                       );

    # Hash{start of match} = [ Location Location Location ... ]
    my @matchedLocations = findMatches ($testCase1, @mappingsList);

    foreach my $location (@matchedLocations) {
        print $location->toString() . "\n";
    }

    return;

    # Simulated selections
#    my @userSelections = [ 


    #printLocationHash (%matchedLocations);
  
    #my @selectedLocations = ();
    #push (@selectedLocations, $matchedLocations{0}[0]);
    #push (@selectedLocations, $matchedLocations{5}[0]);
    #push (@selectedLocations, $matchedLocations{8}[0]);
    #push (@selectedLocations, $matchedLocations{10}[0]);

    #my $regEx = buildRegex (@selectedLocations);

    #print $regEx . "\n";

    #if ($testCase1 =~ m/$regEx/ig) {
        #print "Num matches: " . scalar @- . "\n";
        #print "Success!\n";

        #foreach my $match (@-) {
            #print "$match\n";
        #}
    #}

    
    ## %matchedLocations = sortHashArray(%matchedLocations);
    
    #my @finalLocations = flattenMatchedLocations(%matchedLocations);

    #my $i = 0;
    #foreach my $location (@finalLocations) {
        #print "$i: " . $location->toString() . "\n";
        #$i++;
    #}

    ## How would user select?  essentially &x=7&y=3 ?? 
    ##                         Or maybe &7,3 -- Keep it simple




}
