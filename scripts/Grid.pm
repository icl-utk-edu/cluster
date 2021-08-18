package Grid;

# To Do:
# reduce redundancy between Grid::job_details() and Grid::Job methods
# Replace cqueue name with Queue object everywhere

use strict;
use warnings;
use POSIX;
use Newton;
use Time::Local;
use Data::Dumper;

sub new {
  return bless {};
  }

sub queues {
  my $grid = shift;
  my @lines = Grid::execute('/opt/grid/bin/lx26-amd64/qstat', '-f');
  my %cqueues;
  for(@lines){
    my @ele = split /\s+/;
    next unless defined $ele[2] and $ele[2] =~ /\d+/;
    my ($slots_used, $slots) = split('/', $ele[2]);
    my ($cqueue, $host) = $ele[0] =~ /^(.+)\@(.+)$/;
    my $status = $ele[5] || '';
    $slots = 0 if $status =~ /[dEa]+/;
    my $cq = $grid->cache('cqueues', $cqueue, 'Grid::Queue');
    $cq->{slots} += $slots;
    $cq->{slots_used} += $slots_used;
die $ele[0] unless defined $host;
    my $h = $grid->cache('hosts', $host, 'Grid::Host');
    $cq->add_host($h, $slots);
    $cqueues{ $cqueue } = $cq;
    }
  return values(%cqueues) if wantarray;
  return [values(%cqueues)];
  }

sub cache {
  # return the package object for the cache key name
  # create a new object if necessary
  my $self = shift;
  my ($cache, $key, $package) = @_;
die "$cache $package" unless defined $key;
  return $self->{$cache}->{$key} if exists $self->{$cache}->{$key};
  return $self->{$cache}->{$key} = $package->new($key);
  }

sub jobs {
  my $self = shift;
  my @options;
  for(@_){
    push @options, split(/\s+/);
    }
  push(@options, qw/-u */) unless @options;
  my $job_details = job_details();
  my $string = Grid::execute('/opt/grid/bin/lx26-amd64/qstat', @options, '-xml');
  $string =~ s/\n//gs;
  $string =~ s/<[\/]*queue_info>//g;
  $string =~ s/<[\/]*job_info>//g;
  $string .= '</job_info>';
  my $p = new XML::Parser(Style => 'Tree');
  my $tree = $p->parse($string);
  my $items = $tree->[1];
  my @out;
  for(@$items){
    my $dat = $_;
    next unless ref($dat) eq 'ARRAY';
    my $state = $dat->[0]->{state};
    shift @$dat;
    for(@$dat){
      next unless ref($_) eq 'ARRAY';
      $_ = $_->[2];
      }
    my %hash = @$dat;
    $hash{State} = $state;
    my $host;
    if($hash{queue_name}){
      ($hash{cluster_queue_name}, $host) = $hash{queue_name} =~ /^(.+)\@(.+)$/;
      }
    delete $hash{0};

    for(qw(JB_submission_time JAT_start_time)){ # convert times
      my $key = $_;
      next unless $hash{$key};
      my ($year, $month, $day, $hour, $min, $sec) = $hash{$key} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)$/;
      $month--;
      $hash{$key} = timelocal($sec, $min, $hour, $day, $month, $year);
      }

    my $base_jid = $hash{JB_job_number};
    my $mult = $job_details->{$base_jid}->{mult};
    $hash{M} = $job_details->{$base_jid}->{M};
    $hash{T} = $job_details->{$base_jid}->{T} * $mult;
    $hash{Slots} = $hash{M} * $hash{T};
    $hash{mult} = $mult;
    $hash{grid} = $self;

    my @tasks = expand_sge_tasks($hash{tasks});
    if(@tasks){ # expand array jobs
      for(@tasks){
        my $job = $self->cache('jobs', $hash{JB_job_number}, 'Grid::Job');
        map {$job->{$_}=$hash{$_}} keys %hash;
        $job->{tasks} = $_;
        $job->{JB_job_number} = "$hash{JB_job_number}.$_";
        push @out, $job;
        }
      next;
      }
    $hash{JB_job_number} = "$hash{JB_job_number}.$hash{tasks}" if $hash{tasks};
    my $job = $self->cache('jobs', $hash{JB_job_number}, 'Grid::Job');
    delete $hash{slots};
    map {$job->{$_}=$hash{$_}} keys %hash;
    next if $job->{slots}++ == 1; # don't include the SLAVE host that's also the MASTER

    if(defined $host){ # only relevant for running jobs
      my $h = $self->cache('hosts', $host, 'Grid::Host');
      for(1..$mult){
        $job->add_host($h);
        }
      }
    push @out, $job;
    }
  my $jobs = [values %{$self->{jobs}}];
  return @$jobs if wantarray;
  return $jobs;
  }

sub expand_sge_tasks {
  my $tasks = shift;
  return unless defined $tasks;
  return if $tasks =~ /^\d+$/;
  my @groups = split(/,/, $tasks);
  my @task_ids;
  for(@groups){
    if(/^\d+$/){
      push @task_ids, $_;
      next;
      }
    my ($n1, $n2, $inc) = /^(\d+)-(\d+):(\d+)$/;
    for(my $i=$n1;$i<=$n2;$i+=$inc){
      push @task_ids, $i;
      }
    }
  return @task_ids;
  }

sub job_details {
  my @data = Grid::execute('/opt/grid/bin/lx26-amd64/qstat', '-j', '*');
  my ($job, %jobs);
  for(@data){
    if(/^job_number:\s*(\d+)\s*$/){
      $job = $1;
      $jobs{$job}->{M} = 1;
      $jobs{$job}->{T} = 1;
      $jobs{$job}->{mult} = 1;
      }
    elsif(/^hard resource_list:\s*(\S+)\s*$/){
      my $string = $1;
      if($string =~ /mem=([\d\.]+)/){
        my $memslots = ceil($1/2);
        $jobs{$job}->{mult} *= $memslots;
        }
      if($string =~ /dedicated=(\d+)/){
        $jobs{$job}->{mult} *= $1;
        }
      }
    elsif(/^parallel environment:\s*(\S+)\s*range:\s*(\d+)\s*$/){
      my ($pe, $num) = ($1, $2);
      if($pe =~ /^openmpi/){
        $jobs{$job}->{M} = $num;
        }
      elsif($pe eq 'threads' or $pe eq 'openmp'){
        $jobs{$job}->{T} = $num;
        }
      }
    elsif(/^hard_queue_list:\s*(\S+)/){
      $jobs{$job}->{hard_queue_list} = $1;
      }
    elsif(/^checkpoint_object:\s*(\S+)/){
      $jobs{$job}->{checkpoint} = $1;
      }
    }
  return \%jobs;
  }

sub usage {
  my $self = shift;
  my ($user, $project, $queue) = @_;
  my $qquota = Grid::execute('/opt/grid/bin/lx26-amd64/qquota', 
    '-u', $user, '-P', $project, '-q', $queue->{name}, '-xml',
    );
  $qquota =~ s/\n//gs;
  my $p = new XML::Parser(Style => 'Objects');
  my ($objs) = $p->parse($qquota)->[0]->{Kids};
  my %out;
  for(@$objs){
    next unless ref($_) eq 'Grid::qquota_rule';
    my $rqs_linename = $_->{name};
    my $contents = $_->{Kids};
    for(@$contents){
      next unless ref($_) eq 'Grid::limit';
      my $resource = $_->{resource};
      my ($used) = $_->{value} =~ /^(\d+)/;
      #my $limit = $_->{limit};
      $out{$rqs_linename}->{$resource} = $used;
      last;
      }
    }
  return %out;
  }

sub execute {
  my $cmd = join(' ', @_);
  $cmd =~ s/\*/\\*/gs;
  return `$cmd`;
  }

#################################################################################
package Grid::Job;
use strict;
use warnings;

sub new { 
  bless {};
  }

sub add_host {
  my $self = shift;
  my $host = shift;
  push @{ $self->{hosts} }, $host;
  }

sub pe {
  my $job = shift;
  return $job->{pe} if exists $job->{pe};
  $job->update_details;
  return $job->{pe};
  }

sub hard_queue_list {
  my $job = shift;
  return $job->{hard_queue_list} if exists $job->{hard_queue_list};
  $job->update_details; 
  return $job->{hard_queue_list};
  }

sub complex {
  my $job = shift;
  my $complex = shift;
  return $job->{complex}->{$complex} if exists $job->{complex};
  $job->update_details;
  return $job->{complex}->{$complex};
  }

sub update_details {
  my $job = shift;
  my $id = $job->{JB_job_number};
  my $data = Grid::execute('/opt/grid/bin/lx26-amd64/qstat', '-j', $id);

  ($job->{pe}) = $data =~ /\nparallel environment:\s*(\S+)\s*/s;

  ($job->{hard_queue_list}) = $data =~ /\nhard_queue_list:\s*(\S+)/s;

  my ($complex) = $data =~ /\nhard resource_list:\s*(\S+)/s;
  $complex = '' unless defined $complex;
  $job->{complex} = { map { split('=') } split(',', $complex) };
  }

##############################################################################3
package Grid::Queue;
use strict;
use warnings;

sub new { 
  my $self = shift;
  my $name = shift;
  my @info = Grid::execute('/opt/grid/bin/lx26-amd64/qconf','-sq',$name);
  my ($pe_list) = grep {/^pe_list\s+.*openmpi/} @info;
  my $parallel = (defined $pe_list)?1:0;
  bless {name=>$name, parallel=>$parallel};
  }

sub add_host {
  my $self = shift;
  my ($host, $slots) = @_;
  push @{ $self->{hosts} }, [$host, $slots];
  }

##############################################################################3
package Grid::Host;
use strict;
use warnings;

sub new {
  my $self = shift;
  my $name = shift;
  $name =~ s/\.[^\.]+$//gs;
  bless {name=>$name};
  }

sub jobs {
  my $self = shift;
  my $jobs = $self->{jobs};
  return unless defined $jobs;
  return @$jobs;
  }

sub add_job {
  my $self = shift;
  my $job = shift;
  push @{ $self->{jobs} }, $job;
  }

##############################################################################
package Grid::Limits;
use strict;
use warnings;

sub new { 
  my $rqsl = Grid::execute('/opt/grid/bin/lx26-amd64/qconf','-srqs');
  $rqsl =~ s/\\\s*\n\s*//gs;
  $rqsl =~ s/,\s*/,/gs;
  my @list = split(/\n/, $rqsl);
  my (%last, %limits);
  for(@list){
    my ($key, $value) = /^\s*(\S+)\s*(\S+.+)$/;
    next unless defined $value;
    $last{$key} = $value;
    next unless $key eq 'limit' and $last{enabled} eq 'TRUE';
    my $name = $last{name};
    $value =~ s/to\s+(.+)$//;
    my $limit = $1;
    $value =~ s/\{\*\}/*/g; # simplify {*} because it is understood to apply per user
    my %components = split(/\s+/, $value);
    my %values = map {/^(.+)=(.+)$/;$1,$2} split ',', $limit;
    push(@{ $limits{$name} }, [\%components, \%values]);
    }
  return bless \%limits;
  }

sub limits {
  my $self = shift;
  my %param = @_; # users,projects,queues
  my @limits;
  for(keys %$self){
    my $name = $_;
    my $rqs = $self->{$name};
    my $c = 0;
    for(@$rqs){
      my ($rule, $values) = @$_;
      $c++;
      if( rule_match($rule, \%param) ){
        my %resources;
        for(keys %$values){
          my $res = $_;
          my ($value) = $values->{$res} =~ /^(\d+)/;
          next unless defined $value;
          $resources{$res} = $value;
          }
        next unless %resources;
        push @limits, ["$name/$c", \%resources];
        last;
        }
      }
    }
  return @limits;
  }

sub rule_match {
  my ($rule, $param) = @_;
  for(keys %$rule){ # all rules must match
    return 0 unless key_match($rule->{$_},$param->{$_});
    }
  return 1;
  }

sub key_match {
  my ($match, $value) = @_;
  $value = '' unless defined $value;
  my @patterns = split(/,/, $match); # return 1 if any patterns match
  for(@patterns){
    s/\*/.*/g;
    return 1 if $value =~ /^$_$/;
    }
  return 0;
  }

1;

