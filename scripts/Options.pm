package Options;

use strict;
use warnings;
use Getopt::Long ();
use Data::Dumper;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA         = qw(Exporter);
@EXPORT      = qw(GetOptions);

sub GetOptions {
  Getopt::Long::Configure("bundling");
  my @options;
  my $help = shift;
  for(split /\n/, $help){
    chomp;
    my $value;
    $value = $1 if s/(=\w+)//;
    my ($params) = /^\s+(-+\w+,*\s{0,1}-*[\w]*)\s+/;
    next unless defined $params;
    my @params = map {s/\-//g;s/\s+//;$_} split /,/, $params;
    my $def = join('|', sort {length($b) <=> length($a)} @params);
    $def .= $value if defined $value;
    push @options, $def;
  }
  my %opt;
  my $ok = Getopt::Long::GetOptions(\%opt, @options);
  die $help if not($ok) or $opt{help};
  return %opt;
}

1;

