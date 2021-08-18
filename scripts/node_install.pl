#!/usr/bin/perl

use strict;
use warnings;
use lib "/newton/scripts";
use Newton;

die "Error: This must be executed as root.\n" 
  if $ENV{USER} ne 'root';

my @scripts = glob("/newton/scripts/node_install/*");
for(sort @scripts){
  print `$_`;
  }

