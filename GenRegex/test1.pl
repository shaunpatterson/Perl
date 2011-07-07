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
   my $testCase = "/20.10.1.1/hd/su/staging/packaging/";

   my @mappingsList = Match::getGeneralMappings();

   my @matchedLocations = Match::findMatches ($testCase, @mappingsList);

   Match::printLocations(@matchedLocations);
}

sub test4 {
    my $testCase = "Test one two three";

    my @mappingsList = Match::getGeneralMappings();

    my @matchedLocations = Match::findMatches ($testCase, @mappingsList);
    my %hashedLocations = Match::locationsToHash (@matchedLocations);

    Match::printLocations(@matchedLocations);
    Match::printHashedLocations(%hashedLocations);

    my @maxDepthLocations = Match::getMaxDepthLocations(%hashedLocations);
    print "Max depth: " . scalar @maxDepthLocations . "\n";
    Match::printLocations (@maxDepthLocations);
  
    print "-----------------------\n";

    Match::printLocations(@matchedLocations);
    
    # Select 22: var:(?:[a-z][a-z0-9_]*):two:9:11
    my @userSelections = ( 22 );
    my $regEx = Match::buildRegex(@matchedLocations, @userSelections);
    print "$regEx\n";
        

}



sub main {
    test4();

    # All test cases should return non-zero if passed
#    test1() || print "Failed test1\n";
#    test2() || print "Failed test2\n";
}

1;
