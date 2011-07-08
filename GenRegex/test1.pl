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

    Match::printLocations (@matchedLocations);

    my @userSelections = ( 1, 7, 11, 15 );
    my $regEx = Match::buildRegex ($testCase, @matchedLocations, @userSelections);
    print "$regEx\n";

    unless ("Im gonna need about treefitty" =~ m/$regEx/) {
        print "Treefitty test failed\n";
        return 0;
    }

    if ("1234 blah BLAH 567" =~ m/$regEx/) {
        # Currently failing.  Better regex generation needed
        print "Erroneously matched $1 $2 $3 $4\n";
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

    Match::printLocations (@matchedLocations);

    # Match "Test" completely
    # Then match the other words
    my @userSelections = ( -1, 8, 13, 18 );
    my $regEx = Match::buildRegex ($testCase, @matchedLocations, @userSelections);
    print "$regEx\n";

    unless ("This xxx yyy zzz" =~ m/$regEx/) {
        print "Failed on: This xxx yyy zzz\n";
        return 0;
    }

    if ("Im gonna need about treefitty" =~ m/$regEx/) {
        print "Failed on South Park\n";
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
  
    # Select 22: var:(?:[a-z][a-z0-9_]*):two:9:11
    # This should come back with 2 'unintersting' matches
    #  of a word
    my @userSelections = ( 18 );
    my $regEx = Match::buildRegex($testCase, @matchedLocations, @userSelections);

    if ($regEx ne "(?:[a-z][a-z0-9_]*).*?(?:[a-z][a-z0-9_]*).*?([a-z][a-z0-9_]*)") {
        print "$regEx\nNot expected regex\n";
        return 0;
    }


    print "$regEx\n";
        

}

sub test5 {
    my $testCase = "Test one two three";

    my @mappingsList = Match::getGeneralMappings();

    my @matchedLocations = Match::findMatches ($testCase, @mappingsList);
    my %hashedLocations = Match::locationsToHash (@matchedLocations);

    Match::printLocations(@matchedLocations);
#    Match::printHashedLocations(%hashedLocations);

    my @maxDepthLocations = Match::getMaxDepthLocations(%hashedLocations);
  
    my @userSelections = ( 2, 18 );
    my $regEx = Match::buildRegex($testCase, @matchedLocations, @userSelections);

    print "$regEx\n";

    if ($regEx ne "([a-z]+).*?(?:[a-z][a-z0-9_]*).*?([a-z][a-z0-9_]*)") {
        print "$regEx\nNot expected regex\n";
        return 0;
    }

    return 1;
}

sub test6 {
    my $testCase = "This This is a test";

    my @mappingsList = Match::getGeneralMappings();

    my @matchedLocations = Match::findMatches ($testCase, @mappingsList);
    my %hashedLocations = Match::locationsToHash (@matchedLocations);

    Match::printLocations(@matchedLocations);

    # Match the second "This" completely
    my @userSelections = ( -11 );
    my $regEx = Match::buildRegex($testCase, @matchedLocations, @userSelections);

    print "$regEx\n";

    if ($regEx ne "(?:This).*?(This)") {
        print "$regEx\nNot expected regex\n";
        return 0;
    }

    return 1;
}

sub test7 {
    my $testCase = "Te";

    my @mappingsList = Match::getGeneralMappings();

    my @matchedLocations = Match::findMatches ($testCase, @mappingsList);

    Match::printLocations(@matchedLocations);

}


sub main {
    
    test7();

    # All test cases should return non-zero if passed
    #test1() || print "Failed test1\n";
    #test2() || print "Failed test2\n";
    #test3() || print "Failed test3\n";
    #test4() || print "Failed test4\n";
    #test5() || print "Failed test5\n";
}

1;
