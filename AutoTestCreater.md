#Automate test case generation.

# Introduction #

Automatic test case generation is a program that helps to write test cases for any computer software to has to be tested.
Based on the input data and the test scenarios multiple test cases are created that provides wide range of test coverage.

# Details #

**Automatic test case generation
  1. Write the input test data file that contain raw data.
  1. Write the scenarios file using grammar defined.
  1. Write the rules/conditions.**

**Characters supported:--
  1. Right Curly bracket    "{"  => to open the range content
  1. Left Curly bracket     "}"  => to close the range content
  1. Right Square bracket   "["  => to open the index content
  1. Right Square bracket   "]"  => to close the index content
  1. Two dots define range  ".."
  1. Right parenthesis      "{"  => to open the condition
  1. Left parenthesis       "}"  => to close the condition
  1. The colon              ":"  => to split ranges and indexes**

**Rules for Grammar:--
  1. Define range as => {<int 1>}{<int 2>} or {<int 1>..<int n>}
  1. Define index as => [<int 1>][<int 2>] or [<int 1>..<int n>]
  1. Rules for conditions:--
    1. No rule => ()
    1. Not equal to "!=" => Data1 is not equal to Data 2, string comparison
> > > (Data1 != Data2)
    1. Exists if "exists if" => Data1 exists only if Data2 belongs to some range
> > > (Data1 exists if Data2[[2](2.md)][[3](3.md)])
    1. Not Exists if "!exists if" => Data1 does not exists if Data2 belongs to some range
> > > (Data1 !exists if Data2[[3](3.md)])**

**Sample SampleInput.csv file
  * Data1,Data2,Data3,Data4
  * Value01,Value02,Value03,Value04
  * Value11,Value12,Value13,Value14
  * Value21,Value22,Value23,Value24
  * ,Value01,Value01,Value01
  * ,Value11,Value11,Value11
  * ,Value21,Value21,Value21**

**Sample SampleTestScenario.csv file
  * TestID,Summary,Data1,Data2,Data3,Data4,Expected,Condition
  * 1,Test summary one,{1}:[[0](0.md)],{1},{1},{1},Expected result one,(Data1 exists if Data2[[3](3.md)])
  * 2,Test summary two,{1}:[[0](0.md)],{1}:[3..5],{1},{1},Expected result one,(Data1 != Data2)
  * 3,Test summary three,{1..3},{1},{1},{1},Expected result one,(Data1 != Data2) && (Data1 !exists if Data2[[3](3.md)])**

**Run program using

> perl goDzire.pl -output MyTest.csv -scenario SampleTestScenario.csv -input SampleInput.csv**

**Sample Output file - MyTest.csv
  * 1;,Test summary one;,Value01;,Value01;,Value13;,Value21;,Expected result one,
  * 2;,Test summary two;,Value01;,Value11;,Value11;,Value11;,Expected result one,
  * 3;,Test summary three;,Value11;,Value12;,Value11;,Value24;,Expected result one,
  * 3;,Test summary three;,Value01;Value11;,Value22;,Value13;,Value04;,Expected result one,
  * 3;,Test summary three;,Value21;Value21;Value01;,Value22;,Value11;,Value24;,Expected result one,**


Example : Example.wiki