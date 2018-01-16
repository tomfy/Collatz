#!/usr/bin/perl -w
use strict;
use bigint;
use List::Util qw (sum min max);
use Getopt::Long;

my $fcount = 0;

# iterate the collatz map or variants, until
# a cycle is found, i.e. until return to a previously
# encountered value. e.g. 8->4->2->1->4; in this case there
# are 4 distinct values, and then they repeat. 
# Output some summary
# info: e.g.
#    7      1       52      17          3     1     4
# starting from 7 (col 1), there are 17 distinct values (col 4), min and max
# values encountered are 1 and 52 (cols 2 and 3), 
# the min value in cycle is 1 (col 6), the length of the cycle is 3 (col 5),
# and the first value in the cycle which is encountered on this trajectory is
# 4 (col 7).

my $type = 'collatz';
my $max_start_number = 100;
my $mult = 3;
my $add = 1;
my $max_steps = 1000;
my $verbose = 0;

GetOptions(
           'type=s' => \$type,  # collatz, a, b, etc.
           'max_start_number=i' => \$max_start_number,
           'mult=i' => \$mult,
           'add=i' => \$add,
           'max_steps=i' => \$max_steps,
           'verbose!' => \$verbose,
          );

print "type: $type,  max_start: $max_start_number,  multiplier: $mult,  add: $add,  max_steps: $max_steps.\n";

my %cycle_mins = (); # keys are minimum numbers on cycles, values the number of trajectoried found ending at the corresponding cycle.
my %n_info = (); # keys: starting numbers; values array ref w summary info, e.g.  (3n+1 case): $n_info{5} = [1,16,6,3,1,4]
my %incycle = (); # keys are numbers which are on cycles (values are 1)

print "# n       min      max   steps cycle- length,min,join\n";
for my $n (1..$max_start_number) {
   my @sequence = ();
   my $steps = 0;
   my $max_i = $n;
   my $min_i = $n;
   my $comment = '';

   push @sequence, $n;
   my %number_steps = ($n => 0); # $number_steps{$i} = the number of steps it takes to get to $i starting from $n
   print "#  $steps  $n \n" if($verbose);
   my $i = $n;
   while (1) {
      $i = f($type, $mult, $add, $i);
      $steps++;
      print "#  $steps   $i \n" if($verbose);
      $min_i = min($i, $min_i);
      $max_i = max($i, $max_i);

      # either:
      # we have come to a number which is already done (and which is not on a cycle):
      if (exists $n_info{$i} and !exists $incycle{$i}) {
         my $xinfo = $n_info{$i};
         my @info;
         $info[0] = ($xinfo->[0] < $min_i)? $xinfo->[0] : $min_i;
         $info[1] = ($xinfo->[1] > $max_i)? $xinfo->[1] : $max_i;
         $info[2] = $xinfo->[2] + $steps;
         $info[3] = $xinfo->[3];  # cycle length
         $info[4] =  $xinfo->[4]; # cycle min
         $info[5] =  $xinfo->[5]; # cycle first
         $n_info{$n} = \@info;
         #    print "    zzz:   $n  ", join("; ", @info), "    $i  ", join("; ", @$xinfo), "\n";

         if(0){
         my ($min_j, $max_j) = ($xinfo->[0], $xinfo->[1]);
         my $j_steps = $xinfo->[2];
         while (@sequence) {
            my $j = pop @sequence;
            $min_j = $j if($j < $min_j);
            $max_j = $j if($j > $max_j);
        #    $min_j = min($j, $min_j);
        #    $max_j = max($j, $max_j);
            $j_steps++;
            $n_info{$j}->[0] = $min_j;
            $n_info{$j}->[1] = $max_j;
            $n_info{$j}->[2] = $j_steps;
            $n_info{$j}->[3] = $xinfo->[3];
            $n_info{$j}->[4] = $xinfo->[4];
            $n_info{$j}->[5] = $xinfo->[5];

         #   print $j, "   ", join(", ", @{$n_info{$j}}), "\n";
         }
      }
         last;
      }
      # or:
      # we have come to a number already seen on this trajectory, i.e. have gone around a cycle:
      if (exists $number_steps{$i}) { # have completed a cycle.
         my $cycle_length = $steps - $number_steps{$i};
         my $j = $i;
         my $cycle_first = $i;
         my $cycle_min = $j;
         $incycle{$j} = 1;
         for (1..$cycle_length) {
            $j = f($type, $mult, $add, $j);
            $cycle_min = $j if($j < $cycle_min);
            $incycle{$j} = 1;
            # print "jjjjj: $j \n";
         }
         die "$i $j cyle/cycle length inconsistency.\n" if($i != $j);
         #      print "xxx $i   $steps  ", $number_steps{$i}, "  $cycle_length  $cycle_min \n";
         $n_info{$n} = [$min_i, $max_i, $steps, $cycle_length // '--', $cycle_min // '--', $cycle_first // '--'];
         last;
      }
      # or:
      # we have taken too many steps - give up on the trajectory for this initial number.
      if ($steps > $max_steps) {
         $comment =  "Steps limit ($max_steps) exceeded.";
         last;
      }
      push @sequence, $i;
      $number_steps{$i} = $steps; # record how many steps it took to get to this number.

   }
                          # end of loop over iterations of f.

   # $steps += $number_steps{$i};
   # $number_steps{$n} = $steps;
   #print "$n    ", join("  ", @{$n_info{$n}}), "\n";
   if (exists $n_info{$n}) {
      $cycle_mins{$n_info{$n}->[4]}++;
   } else {
      $cycle_mins{-1}++;
   }
   my @info;                    #  = map($_ // -1, @{$n_info{$n}});
   if (exists $n_info{$n}) {
      #    @info = (-1, -1, -1, -1, -1, -1);
      # }else{
      #    @info = @{$n_info{$n}};
      # }
      printf("%6i  %5i %8i   %5i      %5i %5i %5i\n", $n, @{$n_info{$n}});
   } else {
      printf("%6i  %10s\n", $n, $comment);
   }

}                               # end loop over initial numbers

my @cyclemins = sort { $a <=> $b } keys %cycle_mins;
for (@cyclemins) {
   printf("#  %8i %8i \n",$_, $cycle_mins{$_});
}
print "fcount: $fcount\n";

sub f{
   my $type = shift;
   my $m = shift;
   my $a = shift;
   my $i = shift;
   $fcount++;
   if ($type eq 'collatz') {
      return f_collatz($m, $a, $i);
   } elsif ($type eq 'b') {
      return f_b($m, $a, $i);
   } elsif ($type eq 'a') {
      return f_a($m, $a, $i);
   }
}

sub f_collatz{ 
   # classic collatz problem:
   # odd n-> 3*n + 1; even n -> n/2    and also
   # generalization to odd n -> m*n + a; even n -> n/2
   my $m = shift;
   my $a = shift;
   my $i = shift;
   return (($i % 2) == 0)?
     $i/2:
     $m*$i + $a;
}

sub f_a{                        # odd n -> (n-a)/2; even n -> m*n + a
   my $m = shift;
   my $a = shift;
   my $i = shift;
   return  (($i % 2) != 0)?
     ($i - $a)/2 :
       $m*$i + $a;
}

sub f_b{                  # n % m == 1 n -> m*n ; else n -> int (n/2) 
   my $m = shift;
   my $r = shift;
   my $i = shift;
   return  (($i % $m) == $r)?
     $m*$i:
     ( (($i % 2) == 0)? $i/2 : ($i-1)/2 );
}
