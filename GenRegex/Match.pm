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
# I started this project to learn Perl... so it's definitely not the greatest Perl code in the world.
#  Feel free to contribute or send me suggestions.
#
package Match;

use Location;

use strict;
use warnings;


sub getGeneralMappings {
    # Encode the mapping precedence by offset within a matching array
    my @mappingsList = (
            { "c" => [ "."  ] },
            { "w"   => [ "[a-z]" ] },
            { "ws"   => [ "\\s+" ] },
            { "state"  => [ "(?:(?:AL|AK|AS|AZ|AR|CA|CO|CT|DE|DC|FM|FL|GA|GU|HI|ID|IL|IN|IA|KS|KY|LA|ME|MH|MD|MA|MI|MN|MS|MO|MT|NE|NV|NH|NJ|NM|NY|NC|ND|MP|OH|OK|OR|PW|PA|PR|RI|SC|SD|TN|TX|UT|VT|VI|VA|WA|WV|WI|WY)(?![a-z]))" ] },
            { "var"  => [ "[a-z][a-z0-9_]*" ] },
            { "word" => [ "[a-z]+" ] },
            { "day"  => [ "(?:(?:[0-2]?\\d{1})|(?:[3][01]{1})))(?![\\d]" ] },
            { "int"  => [ "[0-9]+" ] },
            { "hex"  => [ "0x[0-9A-F]{1,}" ] },
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

# This is a total hack to reencode precedence...
sub getMatchPrecedence {
    my ($match) = shift;

    my @precedenceMap = qw( c w ws state var word day int hex month year string username ddmmmyyy unixpath ipaddress );
    
    my $matchPrecedence = 0;
    foreach my $matchTest (@precedenceMap) {
        if ($match eq $matchTest) {
            return $matchPrecedence;
        }

        $matchPrecedence++;
    }

    # Not found
    return -1;
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


#
# Build the regular expression
#
# This is quite nasty and should be refactored into a new class...
#
sub buildRegex ($\@\@) {
    # Assumes user selections are from "left to right"
    my ($input, $matchedLocations, $userSelections) = @_;

    # Constants for the builder
    use constant {
        MATCH_REGEX => 0,   # Match the regex within the string
        MATCH_TEXT  => 1,   # Match the full text within the string
    };

    if (scalar @$userSelections <= 0) {
        return ".*";
    }

    # Convert all matched locations to a hash of
    # $hash[REGEX] = ( position position position );
    my %hashedRegexs;
    foreach my $location (@$matchedLocations) {
        push (@{$hashedRegexs{$location->getRegex()}}, $location->getStart());
    }

    # Simple hash map of $hash{string_pos}
    #  If the string position key exists then
    #  a regular expression match is already selected
    #  for that character
    my %matchedPositions;
    
    # Outputted regex
    my $regEx;

    foreach my $selection (@$userSelections) {
        my $location;
        my $matchContext;
        my $matchType;

        if ($selection < 0) {
            # Negatives correspond to absolute matches
            $location = @$matchedLocations[-$selection];
            $matchContext = $location->getMatch();
            $matchType = MATCH_TEXT;
        } else {
            # Normal, match is by the regex
            $location = @$matchedLocations[$selection];
            $matchContext = $location->getRegex();
            $matchType = MATCH_REGEX;
        }

        # Mark characters as matched
        for (my $i = $location->getStart(); $i <= $location->getEnd(); $i++) {
            # Occupied but nothing "there"
            $matchedPositions{$i} = "";
        }
        # Fill the start with the regular expression match
        $matchedPositions{$location->getStart()} = "(" . $matchContext . ")";
        
        # Look behind to see if the same regular expression could be
        #  matched anywhere else
        my @possiblePrevMatches = ();   # Array of starting indices
        my @poss = findPatternMatches ($input, "", $matchContext);
        foreach my $possibleMatch (@poss) {
            if ($possibleMatch->getStart() < $location->getStart ()) {
                push(@possiblePrevMatches, $possibleMatch->getStart());
            }
        }
        if (scalar @possiblePrevMatches) {
            sort { $a <=> $b } @possiblePrevMatches;
        }
   
        # Now take each possible previous match (they are by match start position)
        #  look at the matched positions from start of match to end of match.
        #  If all spaces are "unoccupied" (ie, the keys do not exist) then insert 
        foreach my $possibleMatch (@possiblePrevMatches) {
            my $occupied = 0;

            # Find the match at the location 
            my $matchLocation;
            foreach my $matchedLocationSearch (@$matchedLocations) {
                if ((
                        $matchType == 0 and
                        $matchedLocationSearch->getStart() == $possibleMatch and
                        $matchedLocationSearch->getRegex() eq $location->getRegex()
                    ) or
                    (
                        $matchType == 1 and
                        $matchedLocationSearch->getStart() == $possibleMatch and
                        $matchedLocationSearch->getMatch() eq $location->getMatch()
                    ))
                {
                    for (my $i = $matchedLocationSearch->getStart(); $i <= $matchedLocationSearch->getEnd(); $i++) {
                        if (exists ($matchedPositions{$i})) {
                            # Occupied. Possible elimination.  Try chopping off the string here 
                            #  and seeing if the regex will still match, if so pop it back onto the list
                            #  of possible matches
                            my $chopped = substr ($input, $i + 1);
                            print "Chopped: $chopped\n";
                            print "Regex test: " . $matchedLocationSearch->getRegex () . "\n";

                            ## Does it still match at the beginning?
                            my $matchRegex = $matchedLocationSearch->getRegex ();
                            if ($chopped =~ m/($matchRegex)/gi and
                                $-[0] == 0) 
                            {
                                print "Still matches at the beginning!\n";
                                push (@possiblePrevMatches, ($i + 1));

                                # Add the match specifications to the list of matches... this
                                #  really should be redesigned better
                                
                                # Store the match before we go screwing with the input string
                                my $matchedString = $1;

                                # Record the start and end of the match relative to the original input string
                                my $start = $-[0] + $i + 1;
                                my $end = $start + length($1) - 1;

                                print "$start $end\n";

                                # Record the match 
                                push (@$matchedLocations, Location->new("", $matchRegex, $matchedString, $start, $end));
                            } 
                            else {
                                $occupied = 1; 
                                print "Match has been eliminated: " . $possibleMatch . "\n";
                            }
                            
                            $occupied = 1; 
                        }
                    }

                    if ($occupied == 0) {
                        # Add this regex to the list but as an "unimportant" match
                        
                        for (my $i = $matchedLocationSearch->getStart(); $i <= $matchedLocationSearch->getEnd(); $i++) {
                            # Occupied but nothing "there"
                            $matchedPositions{$i} = "";
                        }
                        # Fill the start with the regular expression match
                        if ($matchType == 0) {
                            $matchedPositions{$matchedLocationSearch->getStart()} = "(?:" . $matchedLocationSearch->getRegex () . ")";
                        } else {
                            $matchedPositions{$matchedLocationSearch->getStart()} = "(?:" . $matchedLocationSearch->getMatch () . ")";
                        }
                    }
                }
            }
        }

    }

    # Now loop through the matched positions finding "spans"
    # Fill the spans in with .*?
    my $start = 0;
    my @sortedKeys = sort { $a <=> $b } keys %matchedPositions;
    my $end = $sortedKeys[-1];
    for (my $position = $start; $position < $end; $position++) {
        if (!exists ($matchedPositions{$position})) {
            # find the end of the span
            my $spanEnd = $position;
            while (!exists ($matchedPositions{$spanEnd})) {
                $matchedPositions{$spanEnd} = "";
                $spanEnd++;
            }
            $matchedPositions{$position} = ".*?";
        }
    }

    # Now look for any hash entries than are NOT blank entries
    #  and build the regex from there
    foreach my $position (sort { $a <=> $b } keys %matchedPositions) {
        if ($matchedPositions{$position} ne "") {
            $regEx .= $matchedPositions{$position};
        }
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

sub locationSortComparatorReversed ($$) {
    my ($a, $b) = @_;
    

    # Sort by position next
    my $positionComparison = $a->getStart() - $b->getStart();
    if ($positionComparison != 0) {
        return $positionComparison;
    }
    
    # And by the size of the match
    my $sizeComparison = length($b->getMatch()) - length($a->getMatch());
    if ($sizeComparison != 0) {
        return $sizeComparison;
    }

    # And by precedence
    my $precedenceComparison = getMatchPrecedence($b->getName ()) - getMatchPrecedence($a->getName());
    return $precedenceComparison;
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

    @matchedLocations = sort locationSortComparator (@matchedLocations);

    # Now update every element in the list with the list location.  This is
    #  used by the view to easily indicate user selections
    my $index = 0;
    for my $location (@matchedLocations) {
        $location->setIndex ($index);
        $index++;
    }

    return @matchedLocations;
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
