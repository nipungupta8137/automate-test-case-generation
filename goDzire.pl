#!/usr/bin/perl
####################################################################################################
# Author : Nipun Gupta                                                                             #
# Date   : 21-July-2013                                                                            #
#                                                                                                  #
#  Revision History                                                                                #
#  ================                                                                                #
#  v1.0 21-July-2013  Code ok Initial draft.                                                       #
#                                                                                                  #
#                                                                                                  #
#                                                                                                  #
#                                                                                                  #
#                                                                                                  #
# Description :                                                                                    #
#   1. Automatic test case generation                                                              #
#        1. Write the input.csv file that contain the test data.                                   #
#        2. Write the TestScenario.csv file using grammer defined.                                 #
#        3. Write the rules/conditions.                                                            #
#                                                                                                  #
#   2. Characters supported:--                                                                     #
#        1. Right Curly bracket    "{"  => to open the range content                               #
#        2. Left Curly bracket     "}"  => to close the range content                              #
#        3. Right Square bracket   "["  => to open the index content                               #
#        4. Right Square bracket   "]"  => to close the index content                              #
#        5. Two dots define range  ".."                                                            #
#        6. Right paranthesis      "{"  => to open the condition                                   #
#        7. Left paranthesis       "}"  => to close the condition                                  #
#        8. The colon              ":"  => to split ranges and indexes                             #
#                                                                                                  #
#   3. Rules for Grammer:--                                                                        #
#        2. Define range as => {<int 1>}{<int 2>} or {<int 1>..<int n>}                            #
#        3. Define index as => [<int 1>][<int 2>] or [<int 1>..<int n>]                            #
#                                                                                                  #
#   4. Rules for conditions:--                                                                     #
#        0. No rule => ()                                                                          #
#        1. Not equal to "!=" => Data1 is not equal to Data 2, string comparision                  #
#           (Data1 != Data2)                                                                       #
#        2. Exists if "exists if" => Data1 exists only if Data2 belongs to some range              #
#           (Data1 exists if Data2[2][3])                                                          #
#        3. Not Exists if "!exists if" => Data1 does not exists if Data2 belongs to some range     #
#           (Data1 !exists if Data2[3])                                                            #
#                                                                                                  #
#   5. Sample SampleInput.csv file                                                                 #
=head
Data1,Data2,Data3,Data4
Value01,Value02,Value03,Value04
Value11,Value12,Value13,Value14
Value21,Value22,Value23,Value24
,Value01,Value01,Value01
,Value11,Value11,Value11
,Value21,Value21,Value21
=cut
#                                                                                                  #
#    6. Sample SampleTestScenario.csv file                                                         #
=head
TestID,Summary,Data1,Data2,Data3,Data4,Expected,Condition
1,Test summary one,{1}:[0],{1},{1},{1},Expected result one,(Data1 exists if Data2[3])
2,Test summary two,{1}:[0],{1}:[3..5],{1},{1},Expected result one,(Data1 != Data2)
3,Test summary three,{1..3},{1},{1},{1},Expected result one,(Data1 != Data2) && (Data1 !exists if Data2[3])
=cut
#                                                                                                  #
#   7. Run program using                                                                           #
#      perl goDzire.pl -output MyTest.csv -scenario SampleTestScenario.csv -input SampleInput.csv  #
#                                                                                                  #
#   8. Sample Output file - MyTest.csv                                                             #
=head
1;,Test summary one;,Value01;,Value01;,Value13;,Value21;,Expected result one,
2;,Test summary two;,Value01;,Value11;,Value11;,Value11;,Expected result one,
3;,Test summary three;,Value11;,Value12;,Value11;,Value24;,Expected result one,
3;,Test summary three;,Value01;Value11;,Value22;,Value13;,Value04;,Expected result one,
3;,Test summary three;,Value21;Value21;Value01;,Value22;,Value11;,Value24;,Expected result one,
=cut
#                                                                                                  #
#                                                                                                  #
####################################################################################################

use strict;
use warnings;

# make print fast
$| = 1;

# Global Usages
my @scenarioArray = ();
my @testDataArray = ();
my @header        = ();
my %testDataHash;
my $inputTestData;
my $outputFile;
my $testScenarios;

sub hashOfArray {
    my $hashRef = shift;
    my $key     = shift;
    my $value   = shift;
    push @{ $hashRef->{$key} }, $value;
}

# print test data or array of hash
sub printTestData {
    foreach ( keys %testDataHash ) {
        print "\n\n$_ => ";
        my $array = $testDataHash{$_};
        foreach (@$array) {
            print $_ . ",";
        }
    }
}

# Read Input File in an array.
sub file_read () {
    my $fileName  = shift;
    my @inputFile = ();
    unless ($fileName) {
        die "you have not specified any file as command line argument \n";
    }
    unless ( -f $fileName ) {
        die "supplied argument must be an existing file \n";
    }
    open openFD, "$fileName" or die("Could not open input file.");
    @inputFile = <openFD>;
    close(openFD);
    return @inputFile;
}

sub getTestData () {
    my $fileName = shift;
    my $flag     = 0;
    my $line;
    my $i;
    my %hashInitial;
    my @token;

    foreach (@$fileName) {
        $line = $_;
        chomp($line);
        if ( $flag == 0 ) {
            @header = split( /,/, $line );
            $flag = 1;
        }
        else {
            @token = split( /,/, $line );
            $flag = 1;
            for ( $i = 0 ; $i <= $#header ; $i++ ) {
                if ( defined( $token[$i] ) && $token[$i] ne "" ) {
                    hashOfArray( \%hashInitial, $header[$i], $token[$i] );
                }
            }
        }
    }
    return %hashInitial;
}

sub breakToken {
    my $token     = shift;
    my @tokenArr  = ();
    my @resultArr = ();
    @tokenArr = split( /,/, $token );
    foreach (@tokenArr) {
        if ( $_ =~ m/(\d+)\.\.(\d+)/ ) {
            for ( my $k = $1 ; $k <= $2 ; $k++ ) {
                push( @resultArr, $k );
            }
        }
        else {
            push( @resultArr, $_ );
        }
    }
    return @resultArr;
}

sub processScenarios {
    my @token;
    my $range;
    my $index;
    my @arrIndex;
    my @arrRange;
    my $rangeRNG;
    my $random_number;
    my %testCase;

    open( TESTCASES, ">>" . $outputFile );
    print TESTCASES "\n";
    foreach ( my $i = 1 ; $i <= $#scenarioArray ; $i++ ) {
        %testCase            = ();
        @token               = split( /,/, $scenarioArray[$i] );
        $testCase{"TestID"}  = $token[0];
        $testCase{"Summary"} = $token[1];

        foreach ( my $j = 2 ; $j < $#token - 1 ; $j++ ) {
            $range = -1;
            $index = -1;

            if ( $token[$j] =~ /(.*?)\:(.*)/ ) {
                $range = $1;
                $index = $2;
            }
            elsif ( $token[$j] =~ m/({.*})/ ) {
                $range = $1;
                $index = -1;
            }

            $index =~ s/\]\[/,/g;
            $range =~ s/\}\{/,/g;
            $index =~ s/\]|\[//g;
            $range =~ s/\}|\{//g;

            @arrRange = &breakToken($range);
            @arrIndex = &breakToken($index);

            $rangeRNG      = $#arrRange + 1;
            $random_number = int( rand($rangeRNG) );

            # all values are permitted
            if ( $arrIndex[0] == -1 ) {
                pop(@arrIndex);
                my $array = $testDataHash{ $header[ $j - 2 ] };
                foreach (@$array) {
                    push( @arrIndex, $_ );
                }
            }
            else {
                for ( my $k = 0 ; $k <= $#arrIndex ; $k++ ) {
                    $arrIndex[$k] =
                      $testDataHash{ $header[ $j - 2 ] }->[ $arrIndex[$k] ];
                }
            }

            for ( my $l = $arrRange[$random_number] ; $l > 0 ; $l-- ) {
                $rangeRNG      = $#arrIndex + 1;
                $random_number = int( rand($rangeRNG) );

                $testCase{ $header[ $j - 2 ] } .=
                  $arrIndex[$random_number] . ";";
            }
        }

        if ( 0 == validateTestCase( \%testCase, $token[$#token] ) ) {
            $i -= 1;
        }
        else {
            print TESTCASES "\n\"" . $testCase{"TestID"} . "\","
              if ( exists( $testCase{"TestID"} ) );
            print TESTCASES "\"" . $testCase{"Summary"} . "\","
              if ( exists( $testCase{"Summary"} ) );

            foreach (@header) {
                if ( !defined( $testCase{$_} ) ) {
                    $testCase{$_} = "";
                }
				$testCase{$_} =~ s/;/;\n/g;
				chomp($testCase{$_});
                print TESTCASES "\"" . $testCase{$_} . "\",";
            }
            print TESTCASES $token[ $#token - 1 ] . ",";
        }

        printf "\n TestID      : %-11s", $testCase{"TestID"}
          if ( exists( $testCase{"TestID"} ) );
        printf "\n Summary     : %-11s", $testCase{"Summary"}
          if ( exists( $testCase{"Summary"} ) );

        foreach (@header) {
            printf "\n %-11s : %-11s", $_,
              ( exists( $testCase{$_} ) ? $testCase{$_} : "" );
        }
        printf "\n Expected    : %-11s", $token[ $#token - 1 ];
        print "\n=================================================\n";
    }
    close(TESTCASES);
}

sub validateTestCase {
    my $hashTestCase = shift;
    my $condition    = shift;
    my @allCnds      = split( / && /, $condition );
    my $result       = 0;
    my $resultFlag   = 0;
    my $targetElement;
    my $conditionElement;
    my $elementRange;

    foreach (@allCnds) {
        $condition  = $_;
        $resultFlag = 0;
        chomp($condition);

        # Rule no. 0 - exists if
        if ( $condition =~ m/\(\)/ ) {
			print "\n\n STATUS : OK\n";
			return 1;
		}

        # Rule no. 1 - exists if
        if ( $condition =~ m/\((.*) exists if (.*?)\[(.*)\]\)/ ) {
            $targetElement    = $1;
            $conditionElement = $2;
            $elementRange     = $3;

            $elementRange =~ s/\]\[/,/g;
            $elementRange =~ s/\]|\[//g;

            my @arrRange = &breakToken($elementRange);

            foreach (@arrRange) {
                if ( $$hashTestCase{$conditionElement} =~
                    m/$testDataHash{$conditionElement}->[$_]/ )
                {
                    print "\n Rule PASS " . $condition;
                    $resultFlag = 1;
                    last;
                }
            }
            if ( $resultFlag == 0 ) {
                print "\n Rule FAIL " . $condition . " Correction Done";
                $$hashTestCase{$targetElement} = "";
            }
            $result++;
        }

        # Rule no. 2 - != condition
        if ( $condition =~ m/\((.*) \!\= (.*)\)/ ) {
            $targetElement    = $1;
            $conditionElement = $2;

            if ( $$hashTestCase{$targetElement} ne
                $$hashTestCase{$conditionElement} )
            {
                print "\n Rule PASS " . $condition;
                $result++;
            }
            else {
                print "\n Rule FAIL " . $condition . " Re-try the test";
            }

        }

        # Rule no. 3 - !exists if
        if ( $condition =~ m/\((.*) !exists if (.*?)\[(.*)\]\)/ ) {
            $targetElement    = $1;
            $conditionElement = $2;
            $elementRange     = $3;

            $elementRange =~ s/\]\[/,/g;
            $elementRange =~ s/\]|\[//g;

            my @arrRange = &breakToken($elementRange);
            $resultFlag = 1;
            foreach (@arrRange) {
                if ( $$hashTestCase{$conditionElement} =~
                    m/$testDataHash{$conditionElement}->[$_]/ )
                {
                    print "\n Rule FAIL " . $condition . " Correction Done";
                    $resultFlag = 0;
                    $$hashTestCase{$targetElement} = "";
                    last;
                }
            }
            if ( $resultFlag == 1 ) {
                print "\n Rule PASS " . $condition;
            }
            $result++;
        }
    }

    if ( $result != $#allCnds + 1 ) {
        print "\n\n STATUS : NOT OK\n";
        return 0;
    }
    else {
        print "\n\n STATUS : OK\n";
        return 1;
    }
}

sub stretchTestCases {
    my @token;
    my $range;
    my $index;
    my @arrRange;
    my %testCase;
    my $myRange;
    my $breakElement;
    my $breakIndex;
    my @breakRange;

    foreach ( my $i = 1 ; $i <= $#scenarioArray ; $i++ ) {
        %testCase = ();
        @token    = split( /,/, $scenarioArray[$i] );
        $myRange  = -2;

        foreach ( my $j = 2 ; $j < $#token - 1 ; $j++ ) {
            $range = -1;
            $index = "";

            if ( $token[$j] =~ /(.*?)\:(.*)/ ) {
                $range = $1;
                $index = $2;
            }
            elsif ( $token[$j] =~ m/({.*})/ ) {
                $range = $1;
            }

            $range =~ s/\}\{/,/g;
            $range =~ s/\}|\{//g;

            @arrRange = &breakToken($range);

            if ( $myRange < $#arrRange + 1 ) {
                $breakElement = $j;
                $breakIndex   = $index;
                @breakRange   = &breakToken($range);
                $myRange      = $#arrRange + 1;
            }
        }

        for ( my $k = 0 ; $k <= $#breakRange ; $k++ ) {
            print TESTFILE "\n";
            foreach ( my $j = 0 ; $j < $#token ; $j++ ) {
                print TESTFILE $token[$j] . "," if ( $j != $breakElement );
                if ( $j == $breakElement ) {
                    print TESTFILE "{" . $breakRange[$k] . "}";
                    print TESTFILE ":" . $breakIndex if ( $breakIndex ne "" );
                    print TESTFILE ",";
                }
            }
            print TESTFILE $token[$#token];
        }
    }
}

#Step0 - get the file names
for ( my $count = 0 ; $count <= $#ARGV ; $count++ ) {
    if ( $ARGV[$count] eq "-input" ) {
        $inputTestData = $ARGV[ ++$count ];
    }
    if ( $ARGV[$count] eq "-output" ) {
        $outputFile = $ARGV[ ++$count ];
    }
    if ( $ARGV[$count] eq "-scenario" ) {
        $testScenarios = $ARGV[ ++$count ];
    }
}

#Step1 - Read the Test Scenario Sheet
@scenarioArray =
  &file_read($testScenarios);    # Lines Corresponding to test scenarios Only
chomp(@scenarioArray);

#Step2 - Extend the test cases
open( TESTFILE, ">extTest.csv" );
print TESTFILE $scenarioArray[0];
stretchTestCases();
close(TESTFILE);

@scenarioArray =
  &file_read("extTest.csv");     # Lines Corresponding to test scenarios Only
chomp(@scenarioArray);

#Step3 - Read the Input Test Data Sheet
@testDataArray =
  &file_read($inputTestData);    # Lines Corresponding to test data Only

#Step4 - Create the test data as hash of array
%testDataHash = &getTestData( \@testDataArray );

# print test data
printTestData;

#Step5 - start processing the test scenarios
processScenarios();

