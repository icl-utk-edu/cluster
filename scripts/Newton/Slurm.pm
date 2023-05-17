package Newton::Slurm;

use strict;
use warnings;
use Newton;
use File::Temp 'tempfile';

sub create_config {
   my $outfile = shift;
   my @nodes = Newton::nodes(type=>'system');
   my %sets;
   # Create the nodes
   my ($fh, $tempfile) = tempfile();
   for(@nodes){
      my ($basename) = $_->{name} =~ /^([^\.]+)\./;
      print $fh "NodeName=$basename CPUs=1 State=UNKNOWN\n";
      next unless $_->{nodeset};
      push @{$sets{$_->{nodeset}}}, $basename;
   }

   # Create the partitions
   print $fh partition('all', 'ALL', 'YES');
   for(keys %sets){
      my $set = $_;
      my $nodelist = join(',', @{$sets{$set}});
      print $fh partition($set, $nodelist, 'NO');
   }
   close $fh;
   `sudo cp $tempfile $outfile`;
   `sudo chmod 644 $outfile`;
   `sudo systemctl restart slurmctld`;
}

sub partition {
   my ($set, $nodes, $default) = @_;
   return "PartitionName=$set Default=$default MaxTime=1440 State=UP Nodes=$nodes\n\n";
}
1;
