#!/usr/bin/perl
#
# Idea heavily influenced by txt2re.com. Unfortunately txt2re.com isn't (or wasn't at the time) open-sourced. 
#  I was curious how the engine worked... so I built my own.
#
# Regular expressions "stolen" from:  (As far as I can tell all these are in the public domain)
#   - txt2re.com 
#   - http://net.tutsplus.com/tutorials/other/8-regular-expressions-you-should-know/
#   - stackoverflow.com
#
# References:
#   - Regular Expressions Pocket Reference by Tony Stubblebine
#   - Mastering Regular Expressions by Jeffrey Friedl
#
# Shaun Patterson, 2011
# shaunpatterson@gmail.com
#
# Code is released into the public domain. Do with it as you please.
#
package Match;

use Location;

use strict;
use warnings;

sub getGeneralMappings {
    # Encode the mapping precedence by offset within a matching array
    my @mappingsList = (
                            { "char" => [ "."  ] },
                            { "ws"   => [ "\\s+" ] },
                            { "var"  => [ "(?:[a-z][a-z0-9_]*)" ] },
                            { "word" => [ "[a-z]+" ] },
                            { "day"  => [ "(?:(?:[0-2]?\\d{1})|(?:[3][01]{1})))(?![\\d]" ] },
                            { "int"  => [ "[0-9]+" ] },
                            { "month" => [ "(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Sept|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)" ] },
                            { "year"  => [ "(?:(?:[1]{1}\\d{1}\\d{1}\\d{1})|(?:[2]{1}\\d{3})))(?![\\d]" ] }, 
                            { "string" => [ '".*?"' , '\\\'.*?\\\'' ] },
                            { "username" => [ '[a-z][a-z0-9_-]{2,15}' ] },
                            { "ddmmmyyy" => [ "(?:(?:[0-2]?\\d{1})|(?:[3][01]{1}))[-:\\/.](?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Sept|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)[-:\\/.](?:(?:[1]{1}\\d{1}\\d{1}\\d{1})|(?:[2]{1}\\d{3})))(?![\\d]" ] },
                            { "unixpath" => [ "(?:\\/[\\w\\.\\-]+)+" ] },
                            { "ipaddress" => [ "(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))(?![\\d]" ] },
                       );

    return @mappingsList;
}


sub findPatternMatches {
    my ($input, $name, $regex) = @_;

    # Location matches within the string
    my @matchedLocations = ();

    # Total offset relative to the original input string
    my $totalOffset = 0;
    while ($input =~ m/($regex)/ig) {
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
    }

    return @matchedLocations;
}

sub buildRegex (\@\@) {
    my ($matchedLocations, $userSelections) = @_;

    if (scalar @$userSelections <= 0) {
        return ".*";
    }
    
    # Outputted regex
    my $regEx;

    # End of the last match (within the string)
    my $lastEnd = 0; 

    foreach my $selection (@$userSelections) {
        if ($selection >= 0) {
            # Regex selection
            my $location = @$matchedLocations[$selection];
            if ($location->getStart() > $lastEnd) {
                $regEx .= ".*?";    # Non-greedy
            }
            $regEx .= "(" . $location->getRegex() . ")" ;
            
            $lastEnd = $location->getEnd() + 1;
        
        } else {
            # Full text selection
            my $location = @$matchedLocations[-int($selection)];
            $regEx .= "(" . $location->getMatch() . ")";
        
            $lastEnd = $location->getEnd() + 1;
        }

    }
   
    return $regEx;
}


sub locationSortComparator ($$) {
    my ($a, $b) = @_;
    
    # And by the size of the match
    my $sizeComparison = length($a->getMatch()) - length($b->getMatch());
    if ($sizeComparison != 0) {
        return $sizeComparison;
    }

    return $sizeComparison;

    # Sort by position next
    my $positionComparison = $a->getStart() - $b->getStart();
    if ($positionComparison != 0) {
        return $positionComparison;
    }
    
    return $positionComparison;

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

    return sort locationSortComparator (@matchedLocations);
}




# Convert an array of matched locations to a hash of:
# hash{start_of_match} = ( match1 match2 match3 )
sub locationsToHash (\@) {
    my ($matchedLocations) = @_;

    my %hashedLocations;
    
    foreach my $location (@$matchedLocations) {
        push (@{$hashedLocations{$location->getStart()}}, $location);
    }

    return %hashedLocations;
}

# Determine the max "depth" of a search.  That is, 
#  what is the maximum number of regex options for each 
#  individual character.  Return the list at that locations
sub getMaxDepthLocations (\%) {
    my ($hashedLocations) = @_;

    my $maxDepth = -1;
    my $maxDepthLocation = -1;
    foreach my $start (sort { $a <=> $b } keys %$hashedLocations) {
        my $depth = scalar @{$hashedLocations->{$start}};
        if ($maxDepth == -1 or $depth > $maxDepth) {
            $maxDepth = $depth;
            $maxDepthLocation = $start;
        }
    }

    return @{$hashedLocations->{$maxDepthLocation}};
}

# Print an array of locations
sub printLocations (\@) {
    my ($matchedLocations) = @_;

    my $i = 0;
    foreach my $location (@$matchedLocations) {
        print "$i: " . $location->toString() . "\n";
        $i++;
    }
}

# Print a hash of array of matches
sub printHashedLocations (\%) {
    my ($hashedLocations) = @_;
    foreach my $start (sort { $a <=> $b } keys %$hashedLocations) {
        print "$start\n";
        foreach my $location (@{$hashedLocations->{$start}}) {
            print "   " . $location->toString () . "\n";
        }
    }
}

1;
