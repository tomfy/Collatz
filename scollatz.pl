#!/usr/bin/perl -w
use strict;
use bigint;
use List::Util qw (sum min max);
use Getopt::Long;

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

# for each i=1..$max_start_number
# iterate  i-> (i even)? i/2 : $mult * i + $add
# until 1 is reached
# output i min, max numbers reached, number of steps to 1

my %cycle_mins = ();
my %n_info = ();
my %incycle = ();
# example (3n+1 case): $n_info{5} = [1,16,6,3,1,4] i.e. min, max, steps (before repeating), cycle length, min, cycle entry point
#my $cycle_number = 1;
print "# n       min      max   steps cycle- length,min,join\n";
for my $n (1..$max_start_number) {
 #  $n_info{$n} = [];
   my $cycle_length = undef;
   my $cycle_min = undef;
   my $cycle_first = undef;
   my @sequence = ();
   my $steps = 0;
   my $max_i = $n;              # -1;
   my $min_i = $n;
   my $i = $n;

   #print "0 $i \n";
   my $sequence_min = $i;
   push @sequence, $i;
   my %number_steps = ($i => 0);
   print "#  $steps  $i \n" if($verbose);
   #	while(1 or (!exists $number_steps{$i})){
   #   while ( ($i != 1) and ($steps < $max_steps)) {
   while (1) {
      if($steps > $max_steps){
         print STDERR "Max number of steps ($max_steps) exceeded. Quitting.\n";
     #    $n_info{$n} = [undef, undef, undef, undef, undef, undef];
         last;
      }
      #     $i = f($mult, $add, $i);
      $i = f($type, $mult, $add, $i);
      $steps++;
      #    print "$steps  $i \n";

      #printf( "%i %g \n", $steps, $i);
      print "#  $steps   $i \n" if($verbose);
      if ($i < $min_i) {
         $min_i = $i;
      }
      if ($i > $max_i) {
         $max_i = $i;
      }

      if (exists $n_info{$i} and !exists $incycle{$i}) {
         my $xinfo = $n_info{$i};
         my @info;
         $info[0] = min($xinfo->[0], $min_i);
         $info[1] = max($xinfo->[1], $max_i);
         $info[2] = $xinfo->[2] + $steps;
         $info[3] = $xinfo->[3];  # cycle length
         $info[4] =  $xinfo->[4]; # cycle min
         $info[5] =  $xinfo->[5]; # cycle first
         $n_info{$n} = \@info;
     #    print "    zzz:   $n  ", join("; ", @info), "    $i  ", join("; ", @$xinfo), "\n";
         last;
      }

      if (exists $number_steps{$i}) { # have completed a cycle.
         $cycle_length = $steps - $number_steps{$i};
         my $j = $i;
         $cycle_first = $i;
         $cycle_min = $j;
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
      $sequence_min = ($i < $sequence_min)? $i: $sequence_min;
      push @sequence, $i;
      $number_steps{$i} = $steps;
      #  print "$i  $steps  ", $number_steps{$i}, "\n";
   } # end of loop over iterations of f.

   # $steps += $number_steps{$i};
   # $number_steps{$n} = $steps;
   #print "$n    ", join("  ", @{$n_info{$n}}), "\n";
   $cycle_mins{$n_info{$n}->[4]}++;
 my @info; #  = map($_ // -1, @{$n_info{$n}});
   if(!exists $n_info{$n}){
      @info = (-1, -1, -1, -1, -1, -1);
   }else{
      @info = @{$n_info{$n}};
   }
   printf("%6i  %5i %8i   %5i      %5i %5i %5i\n", $n, @info); # {$n_info{$n}});
   #$n, $min_i, $max_i, $steps, $cycle_length // '--', $cycle_min // '--', $cycle_first // '--');
   #	print "$n     $sequence_min     $steps   $cycle_length   ", $steps - $cycle_length, "\n";
}  # end loop over initial numbers

my @cyclemins = sort { $a <=> $b } keys %cycle_mins;
for (@cyclemins) {
   printf("#  %8i %8i \n",$_, $cycle_mins{$_});
}

sub f{
   my $type = shift;
   my $m = shift;
   my $a = shift;
   my $i = shift;
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
