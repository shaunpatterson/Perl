#!/usr/bin/perl
package Test1;

use strict;
use warnings;

use Match;

unless (caller) {
    main();
}

sub test1 {
    my $testCase = "This is an example";

    # Custom mapping for this test
    my @mappingsList = (
                            { "char" => [ "."  ] },
                            { "word" => [ "[a-z]+" ] },
                        );

    my @matchedLocations = Match::findMatches ($testCase, @mappingsList);
   
    if (scalar @matchedLocations != 22) {
        return 0;
    }

    my @userSelections = ( 18, 19, 20, 21 );
    my $regEx = Match::buildRegex (@matchedLocations, @userSelections);
    print "$regEx\n";

    unless ("Im gonna need about treefitty" =~ m/$regEx/) {
        return 0;
    }

    if ("1234 blah BLAH 567" =~ m/$regEx/) {
        # Currently failing.  Better regex generation needed
        return 0;
    }

    return 1;
}

sub test2 {
    my $testCase = "This is an example";

    # Custom mapping for this test
    my @mappingsList = (
                            { "char" => [ "."  ] },
                            { "ws"   => [ "\\s+" ] },
                            { "word" => [ "[a-z]+" ] },
                        );

    my @matchedLocations = Match::findMatches ($testCase, @mappingsList);
   
    if (scalar @matchedLocations != 25) {
        return 0;
    }

    my @userSelections = ( -21, 18, 22, 19, 23, 20, 24 );
    my $regEx = Match::buildRegex (@matchedLocations, @userSelections);
    print "$regEx\n";

    unless ("This xxx yyy zzz" =~ m/$regEx/) {
        return 0;
    }

    if ("Im gonna need about treefitty" =~ m/$regEx/) {
        return 0;
    }

    return 1;
}

sub test3 {
    
}


sub main {
    my $test = "11-27-1983";

    if ($test =~ m/(?:(\d+)-(\d+)-(\d+))/) {
        print "Match! $1 $2\n";
    }

    # All test cases should return non-zero if passed
#    test1() || print "Failed test1\n";
#    test2() || print "Failed test2\n";
}

1;
