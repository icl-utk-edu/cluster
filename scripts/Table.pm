package Table;

use strict;
use warnings;

sub new {bless {data => undef, lengths=>[]}}

sub Print {
  my $self = shift;
  my $data = $self->{data};
  for(@$data){
    my @row = @$_;
    my $c = 0;
    for(@row){
      print ' ' x ($self->{lengths}->[$c++] - length($_) + 2);
      print;
      }
    print "\n";
    }
  }

sub add_row {
  my $self = shift;
  my @row = @_;
  my $c = 0;
  for(@row){
    $_ = 'NA' unless defined; 
    $self->{lengths}->[$c-1] = length if length >= ($self->{lengths}->[$c++] || 0);
    }
  push @{$self->{data}}, \@row;
  }

1;

