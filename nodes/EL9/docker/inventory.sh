#!/usr/bin/perl

use strict;
use warnings;
use File::Copy 'move';

my $server = "https://admin.icl.utk.edu/inventory/";
my $curl = "curl --silent --insecure";
my $dest = "/etc/cron.daily/inventory";
my $authkey = 'null';

$ENV{PATH} = '/bin:/usr/bin:/sbin:/usr/sbin';
#check_deps();

my $option = shift @ARGV || '';
#selfcheck() if $option eq '--check';
#check_update() unless $option eq '--noupdate';

my $hostid = dmi('system-uuid') . dmi('baseboard-serial-number') . dmi('system-serial-number');
$hostid = getMAC() if $hostid !~ /\S+/;

my ($admin, $patchdate) = yumhistory();
$admin = check_root_login() unless defined $admin;

Send(hostname=>`hostname`);
Send(
  uuid 			=> dmi('system-uuid'),
  serialNumber		=> dmi('system-serial-number'),
  operatingsystem 	=> OS(),
  manufacturer 		=> dmi('system-manufacturer', 'baseboard-manufacturer'),
  product 		=> dmi('system-product-name', 'baseboard-product-name'),
  patchdate 		=> $patchdate,
  updates		=> updates(),
  needsReboot 		=> needsReboot(),
  administrator		=> $admin,
  ip 			=> 'REMOTE_ADDR',
  checkin 		=> time,
  reboot 		=> check_reboot(),
  RootPwdChange 	=> RootPwdChange(),
  #tenable 		=> tenable(),
  subscription 		=> subscription(),
  recentUsers 		=> recentUsers(),
  CPU 			=> getCPUmodel(),
  CPUinfo 		=> getCPUinfo(),
  RAM 			=> getRAM(),
  GPU 			=> getGPU(),
  NV_driver             => get_NV_driver_version(),
  Kernel		=> getKernel(),
  CPUfamily		=> getCPUfamily(),
  Interconnect		=> getInterconnect(),
  Software		=> getSoftware(),
);

#------------------------------------------------------------------------------

sub updates {
  my @updates = `yum -C check-update --quiet 2>&1`;
  my @security = `yum -C check-update --quiet --security 2>&1`;
  my $packages =  @security + @updates / 1000;
  return $packages;
}

sub getStorage {
  # return the total size of all block devices in GB
  my @devs = `lsblk -dbn`;
  my $total = 0;
  for(@devs){
    my @in = split /\s+/;
    $total += $in[3];
  }
  return int($total/1024/1024/1024);
}

sub getKernel {
  my $rel = `uname -r`;
  chomp $rel;
  $rel =~ s/.x86_64$//;
  return $rel;
}

sub getCPUfamily {
  my ($name) = find(qr/\(synth\).+\(([\w\d\s]+).*?/, `cpuid 2>&1`);
  return $name;
}

sub getInterconnect {
  return '';
}


sub getSoftware {
  my @soft;

  my ($cuda) = find(qr/release ([\d\.]+)/, `/usr/local/cuda/bin/nvcc -V 2>&1`);
  push(@soft, "CUDA($cuda)") if defined $cuda;

  my ($mpss) = find(qr/MPSS Version\s+:\s+([\d\.\-]+)/, `micinfo 2>&1`);
  push(@soft, "MPSS($mpss)") if defined $mpss;

  return join(' ', @soft);
}

sub find {
  my $regex = shift;
  my @dat = @_;
  my $file = $dat[0];
  if(defined $file and not defined $dat[1]){
    chomp $file;
    if(-f $file){
      open(IN, $file) or die $!;
      @dat = <IN>;
      close IN;
    }
  } 
  my @found = grep {defined} map {/$regex/; $1} @dat;
  return @found if wantarray;
  return shift @found;
}

sub getMAC {
  my ($dev) = map {/dev (\S+) /; $1} grep /^default\s+/, `ip route list`;
  my ($mac) = map {/(..:..:..:..:..:..)/; $1} `ip -o link show $dev`;
  return lc $mac;
}

sub getCPUmodel {
  my $model = find(qr/^model name\s+: (.+)$/, '/proc/cpuinfo');
  $model ||= find(qr/^cpu\s+: (.+)$/, '/proc/cpuinfo');
  return $model;
}


sub getCPUinfo {
  my $siblings = find(qr/^siblings\s+: (\d+)/, '/proc/cpuinfo');
  my $cores = find(qr/^cpu cores\s+: (\d+)/, '/proc/cpuinfo');
  my @total = find(qr/^processor\s+: (\d+)/, '/proc/cpuinfo');
  $siblings = @total unless defined $siblings;
  $cores = @total unless defined $cores;
  my $hyper = $siblings != $cores ? 'on' : 'off';
  my $sockets = @total / $siblings;
  return "${sockets}x$cores cores<br>SMT:$hyper";
}

sub getRAM {
  my ($mem) = map {(split /\s+/)[1]} grep /^Mem:/, `free`;
  return int($mem / 1024 / 1000 );
}

sub getGPU {
  my @devs = (nvidia_GPU(), amd_GPU());
  my @numbers = qw/One Two Three Four Five Six Seven Eight/;
  my %gpu;
  my $product;
  for(@devs){
    $gpu{$_}++;
  }
  return join("<br>", map {my $num=$numbers[$gpu{$_}-1]; "$num $_"} keys %gpu);
}

sub nvidia_GPU {
  #GPU 0: NVIDIA A100-SXM4-80GB (UUID: GPU-207798b0-3a6d-bb1c-1a5d-54e286cfceb6)
  return map {/NVIDIA/ ? $_ : "NVIDIA $_"}
         map {chomp; join(' ', (split(/\s+/))[2,3])}
         grep /GPU/, `nvidia-smi -L 2>&1`;
  }

sub amd_GPU {
#*******                  
#Agent 4                  
#*******                  
#  Name:                    gfx90a                             
#  Uuid:                    GPU-a3876accf7c424e3               
#  Marketing Name:          Something maybe
#  Vendor Name:             AMD
  my %custom = (gfx906=>'MI50', gfx90a=>'MI210');
  my (%info, @out);
  for(`rocminfo 2>&1`){
    next unless /^\s+(.+):\s+(.+?)\s*$/;
    $info{$1} = $2;
    if($1 eq 'Device Type' and $2 eq 'GPU'){
      my ($code, $device, $vendor) = map {$info{$_}} ('Name', 'Marketing Name', 'Vendor Name');
      $device = $custom{$code} if $device !~ /\S+/;
      $device ||= 'Unknown';
      my $fullname = "$device ($code)";
      $fullname = "$vendor $fullname" unless $fullname =~ /$vendor/;
      push @out, $fullname;
      undef %info;
    }
  }
  return @out;
}

sub get_NV_driver_version {
  open(IN, '/sys/module/nvidia/version') || return '';
  my $version = <IN>;
  close IN;
  chomp $version;
  return $version;
}

sub needsReboot {
  return 'unknown' unless `which needs-restarting 2>/dev/null`;
  return 'yes' if `needs-restarting`;
  return 'no';
}

sub recentUsers {
  my @logins = `lastlog -t 30`;
  shift @logins; # remove the first line
  return join(' ', map {/^(\S+)/;$1} @logins);
}

sub subscription {
  return "n/a" unless OS() =~ /^Red Hat Enterprise Linux/;
  my ($junk, $status) = map { split(/: */, $_) } grep(/Overall Status/, split(/\n/,`subscription-manager status`));
  return "classic" if $status eq "Unknown";
  ($junk, $status) = map { split(/ *= */, $_) } split(/\n/, `grep '^hostname = ' /etc/rhsm/rhsm.conf`);
  return "satellite" if $status =~ /\.utk\.edu$/;
  return "current" if $status =~ /\.redhat\.com$/;
  return "unknown";
}

sub tenable {
  my ($cmd) = grep {! system("which $_ >/dev/null 2>&1")} qw/pidof pgrep/;
  return 'unknown' unless defined $cmd;
  my $pid = `$cmd nessusd 2>/dev/null`;
  return 'yes' if $pid =~ /\d+/;
  return 'no';
}

sub RootPwdChange {
  my $dtime = find(qr/^root:[^:]*:(\d+):/, '/etc/shadow');
  $dtime ||= 0;
  return $dtime * 3600 * 24;
}

sub check_root_login {
  # Find the user who last logged in directly as root
  my ($fp, $user);
  my $pid = 0;
  open(LOG, '/var/log/secure') or return;
  while(<LOG>){
    if( /sshd\[(\d+)\]: Found matching \S+ key: ([\w\:]+)/ ){
      $pid = $1;
      $fp = $2;
    }
    next unless /sshd\[(\d+)\]: Accepted publickey for root /;
    next unless $1 eq $pid;
    return $_ for find_user($fp);
  }
  close LOG;
  return;
}

sub find_user {
  my $fp = shift;
  my $user;
  my $tmpfile = '/tmp/.' . rand();
  open(IN, '/root/.ssh/authorized_keys') or die $!;
  while(<IN>){
    my $line = $_;
    open(OUT, "+> $tmpfile") or die $!;
    flock(OUT, 2) or die $!;
    print OUT $line;
    close OUT;
    my $test = `ssh-keygen -lf $tmpfile`;
    my (undef, $testkey) = split(/\s+/, $test);
    if($testkey eq $fp){
      $user = ( split(/\s+/, $line) )[2];
      next unless defined $user;
      last;
    }
  }
  close IN;
  unlink $tmpfile;
  return $user;
}

#------------------------------------------------------------------------------

sub OS {
  my @files = grep !/lsb-release/, glob('/etc/*-release');
  unshift @files, '/etc/system-release';
  for(@files){
    my $file = $_;
    next unless -e $file;
    my $OS = file($file);
    chomp $OS;
    if($OS =~ /NAME="([^"]+)"\nVERSION="([^"]+)"/s){
      $OS = "$1 $2";
    }
    $OS =~ s/\(.+?\)//gs;
    return $OS;
  }
  return 'unknown';
}

#------------------------------------------------------------------------------

sub yumhistory {
  my @updates = grep {defined $_->[3] and $_->[3] =~ /U/}
                map {s/^\s+//; chomp; [split /\s+\|\s+/]}
                `yum history list all 2>&1`;
  return unless @updates;
  for(@updates){
    my ($tid, $userstring) = @$_;
    $userstring =~ /<(.+?)>/;
    if(not(defined $admin) and defined $1 and $1 ne 'root' and $1 ne 'unset' and $1 !~ /^\d+$/){
      $admin = $1;
    }
    return($admin, $_->[2]) if grep /Update/, `yum history info $tid 2>&1`;
    #my ($command) = `yum history info $tid 2>&1` =~ /Command Line\s*:(.+?)\n/s;
    #next unless defined $command;
    #return($admin, $_->[2]) if $command =~ /yum-daily\.yum$/;
    #next if $command !~ / update\s*(.*?)$/;
    #my $pat = $1;
    #next if $pat =~ /\S+/ && $pat !~ /^--skip-broken$/;
    return $admin, $_->[2];
  }
}

sub Send {
  my %info = @_;
  for(keys %info){
    my $key = $_;
    my $value = $info{$_};
    $value = '' unless defined $value;
    $value =~ s/'/"/gs;
    $value =~ s/\s+/ /gs;
    my $return = `$curl --data 'payload=$hostid=$authkey=$key=$value' $server/hostreport.cgi`; 
    print "Sending $key=$value return=$return\n" if $option =~ /\-v/;
  }
}

sub check_deps {
  die "Error: Requires the 'dmidecode' utility.\n" 
    unless `which dmidecode`;
  die "Error: Requires the 'curl' utility.\n"
    unless `which curl`;
}

sub check_update {
  my $tmpfile = '/tmp/' . rand();
  return if system("$curl -o $tmpfile $server/inventory.cron");
  if(-e $tmpfile and -e $dest and file($tmpfile) eq file($dest)){
    unlink $tmpfile;
    return;
  }
  chmod 0700, $tmpfile;
  my $check = `$tmpfile --check`;
  chomp $check;
  if($check eq 'OK'){
    move($tmpfile, $dest) or die $!;
    chmod 0700, $dest;
  } else {
    warn "Downloaded script fails sanity check.";
  }
  system("$dest --noupdate");
  exit;
}

sub dmi {
  for(@_){
    my $key = $_;
    my $value = `dmidecode -s $key 2>/dev/null`;
    next unless defined $value;
    chomp $value;
    return $value;
  }
  return '';
}

sub file {
  my $file = shift;
  open(IN, $file) or return;
  my $out = join('', <IN>);
  close IN;
  return $out;
}

sub check_reboot {
  my $reboot_time = `who -b`;
  $reboot_time =~ s/^ *system boot *//;
  chomp $reboot_time;
  return $reboot_time;
}

sub selfcheck {
  # This must be the last function in the file
  print 'OK';
  exit;
}

