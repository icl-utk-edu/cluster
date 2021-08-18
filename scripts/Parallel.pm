package Parallel;

use strict;
use warnings;
use POSIX ':sys_wait_h';
use File::Temp 'tempfile';
use Time::HiRes 'usleep';

sub new { shift; bless { count=>10, @_, running=>0} }

sub run {
  my $P = shift;
  my ($id, $func, @args) = @_;
  my (undef, $file) = tempfile(UNLINK=>1, OPEN=>1);
  while($P->{running} == $P->{count}){
    for( @{ $P->{tasks} } ){
      my $child = $_->{pid};
      my $test = waitpid($child, WNOHANG);
      $P->{running} -=1 if $child == $test;
    }
    usleep 250;
  }
  my $pid = fork;
  push(@{$P->{tasks}}, {pid=>$pid, id=>$id, file=>$file});
  $P->{running}++;
  return if $pid;
  open(OUT, "+>$file") or die $!;
  flock(OUT, 2) or die $!;
  print OUT &$func(@args);
  close OUT;
  exit;
}

sub finish {
  my $P = shift;
  my $tasks = $P->{tasks};
  waitpid($_->{pid},0) for @$tasks;
  for(@$tasks){
    open(IN, $_->{file}) or die $!;
    my @data = <IN>;
    close IN;
    unlink $_->{file};
    $_->{data} = \@data;
  }
  return @$tasks if wantarray;
  return $tasks;
}

1;

