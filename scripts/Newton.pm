package Newton;

use strict;
use warnings;
use Newton::Slurm;
use DBI;
use HTML::Template;
use Data::Dumper;
use POSIX ':sys_wait_h';
use English qw( -no_match_vars );
use XML::Parser;
use File::Temp qw(tempfile tempdir);
use Net::LDAPS;
use LWP::Simple 'get';
use Storable 'thaw';
use Digest::MD5 qw/md5_base64 md5_hex/;
use URI::Escape;
use Parallel;
use File::Copy;

our $adminEmail = 'Newton_HPC_help@utk.edu';
our $IPMIUSER = 'icl';
my $ssh_cmd = "ssh -nqxC -o 'ConnectTimeout=2' -o 'BatchMode=yes'";
my $db;

sub basedir {
  $0 =~ /^(.+\/)scripts\/[^\/]+$/;
  die unless defined $1;
  return $1;
  }

sub db {
  return $db if defined $db;
  my $basedir = basedir();
  my $dbfile = $basedir . 'cluster.db';
  copy("$basedir/scripts/db.init", $dbfile) unless -e $dbfile;
  $db = DBI->connect("dbi:SQLite:dbname=$dbfile","","") || die $DBI::errstr;
  $db->do('PRAGMA foreign_keys = ON');
  $db->do('PRAGMA defer_foreign_keys = ON');
  $db->{AutoCommit} = 1;
  $db->{RaiseError} = 1;
  return $db;
  }

sub ldap {
  my ($netid, $query) = @_;
  die "usage: ldap(<netid>,<query>)" unless defined $netid and defined $query;
  my $ldap = Net::LDAPS->new ( "ldap.utk.edu:636" ) or die "$@";
  my $msg = $ldap->bind ( version => 3 );

  my ($ent) = $ldap->search(
    base   => "dc=tennessee,dc=edu",
    filter => "uid=$netid"
    )->entries;
  return unless defined $ent;
  my $dn = $ent->dn();

  my $result = $ldap->search(
    base    => $dn,
    scope   => "sub",
    filter  => "uid=$netid",
    attrs   =>  [$query],
    );
  ($ent) = $result->entries;
  return unless $ent;
  return $ent->get_value($query);
}

sub ipmi {
  my ($cmd, $ip, $passwd, $user) = @_;
  $passwd ||= bmc_passwd();
  $user ||= $IPMIUSER;
  my @out;
  for( ref($ip) ? @$ip : $ip){
    my @data;
    for my $int ('lanplus', 'lan'){
       my $cmd = "/usr/bin/ipmitool -C 3 -I $int -H $_ -U $user -P $passwd $cmd";
       @data = `$cmd 2>&1`;
       last unless $?;
    }
    return @data unless ref($ip);
    push @out, \@data;
    }
  return @out;
  }

sub get_passwd {
  my $msg = shift || 'Password';
  print STDERR "$msg: ";
  system "stty -echo";
  my $passwd = <STDIN>;
  system "stty echo";
  chomp $passwd;
  print STDERR "\n";
  return $passwd;
  }

sub nodes {
  my %opt = ( name=>undef, where=>undef, type=>'system', @_ );
  my $db = db();
  my @where = ('type=?');
  if($opt{name}){
    push(@where, 'name LIKE ?');
    $opt{name} .= '%';
    }
  push(@where, $opt{where}) if $opt{where};
  my $where = join(' AND ', @where);
  my $sth = $db->prepare("SELECT * from addresses WHERE $where ORDER BY name");
  my @values = grep {defined $_} map {$opt{$_}} qw(type name where);
  $sth->execute(@values);
  my @out;
  while(my $hash = $sth->fetchrow_hashref){
    $hash->{ip} = ipaddr($hash->{ip});
    $hash->{mac} = macaddr($hash->{mac});
    push @out, $hash;
    }
  return @out if wantarray;
  return \@out;
  }

sub runall {
  my %opt = (type=>'system', @_);
  my $func = \&ssh;
  if($opt{ipmi}){
    $func = \&ipmi;
    $opt{type} = 'bmc';
    bmc_passwd();
  }
  my $nodes = nodes(%opt);
  my $jobs = Parallel->new();
  for(@$nodes){
    my $node = $opt{ipmi} ? $_->{'system'} : $_->{name};
    $jobs->run($node, $func, $opt{command}, $_->{ip});
  }
  return $jobs->finish();
}

my @runall_status;
sub runall_status {
  my ($col, $status) = @_;
  $runall_status[$col] = $status;
  print "\f";
  print for(@runall_status);
  }

sub ping {
  my $ip = shift;
  `ping -c1 -W2 $ip`;
  #warn "No ping: $ip\n" if $?;
  return not $?;
  }

sub ssh {
  my ($cmd, $node, $file, $timeout) = @_;
  $timeout ||= 60;
  $file ||= '-';
  (my $hostname = $node) =~ s/^.+\@//;
  `ping -c1 -W1 $hostname 2>&1`;
  my $outfile = ($file eq '-')?'/tmp/.run'.rand():$file;
  if($?){
    `touch $outfile`;
    return;
    }
  else {
    eval {
      local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
      alarm $timeout;
      #print qq/ssh -nqxC -o 'ConnectTimeout=$timeout' -o 'BatchMode=yes' $node "$cmd" >& $outfile\n/;
      my @return = system(qq/ssh -nqxC -o 'ConnectTimeout=$timeout' -o 'BatchMode=yes' $node "$cmd" >& $outfile/);
      alarm 0;
      unless($file eq '-'){
        return @return if wantarray;
        return join('', @return);
        }
      };
    if ($@) {
      return 'timeout' if $file eq '-';
      `echo timeout > $outfile`;
      return 0;
      }
    }
  my @out;
  open(IN, $outfile) or return;
  for(<IN>){
    push @out, $_;
  }
  close IN;
  return @out if wantarray;
  return join('', @out);
  }

sub arrayhashref {
  my ($db, $query, @options) = @_;
  my $sth = $db->prepare($query);
  $sth->execute(@options);
  my @out;
  while(my $tmp = $sth->fetchrow_hashref){
    push @out, $tmp;
    }
  return @out;
  }

sub tmpl {
  my $file = shift;
  my $out = shift;
  my $tmpl = HTML::Template->new(
    filename => $file,
    die_on_bad_params => 0,
    );
  $tmpl->param(@_);
  open(ZONE, "+> $out") or die $!;
  flock(ZONE, 2);
  print ZONE $tmpl->output;
  close ZONE;
  }

sub file {
  my $file = shift;
  open(IN, $file) or die $!;
  flock(IN, 2);
  my $data;
  while(<IN>){
    $data .= $_;
    }
  close IN;
  return $data;
  }

sub daemonize {
  exit if fork;
  POSIX::setsid();
  close(STDOUT);
  close(STDERR);
  close(STDIN);
  }

sub single_instance {
  my $file = shift;
  open(LOCK, "+> /tmp/$file") or die $!;
  my $ok = flock(LOCK, 6);
  die("This program is already running.") unless $ok;
  }

sub tfile {
  my $file = '/tmp/.tfile-'.rand();
  open(TF, "+>$file") or die $!;
  flock(TF, 2);
  return *TF;
  }

sub new_ip {
  my $domain = shift;
  my $DB = db();
  my ($ip1, $ip2) = $DB->selectrow_array(
    'SELECT ip1,ip2 FROM domains WHERE domain=?',
    undef, $domain,
    );
  my $ip1n = ip2i($ip1);
  my $ip2n = ip2i($ip2);
  my $ips = $DB->selectall_arrayref('SELECT ip FROM addresses'); 
  my %ips = map {ip2i($_->[0]),1,ip2i($_->[1]),1} @$ips;
  for($ip1n..$ip2n){
    next if $ips{$_};
    return i2ip($_);
    }
  return;
  }

sub ip2i { 
  # convert an ip to an integer
  my $ip = shift;
  return 0 unless $ip;
  my @nums = split(/\./, $ip);
  my ($mult, $output) = (0, 0);
  for(reverse @nums){
    $output += $_*256**($mult++);
    }
  return $output;
  }    
  
sub i2ip {
  # convert and integer into an ip
  my $int = shift;
  my @out;
  for(1..4){ 
    my $remains = $int % 256;
    push @out, $remains;
    $int = int($int/256);
    }
  return join('.', reverse @out);
  }

sub execute {
  # Execute a command and return the STDOUT while bypassing the shell.
  # Taken from perlsec
  my @cmd = @_;
  #if($cmd[0] !~ /^\//){
  #  my $path = `which $cmd[0]`;
  #  chomp $path;
  #  $cmd[0] = $path;
  #  }
  my $pid;
  die "Can't fork: $!" unless defined($pid = open(KID, "-|"));
  my @out;
  if($pid){ # parent
    while (<KID>) {
      push @out, $_;
      }
    close KID;
    return @out if(wantarray);
    return join('', @out);
    }
  else {
    my @temp     = ($EUID, $EGID);
    my $orig_uid = $UID;
    my $orig_gid = $GID;
    $EUID = $UID;
    $EGID = $GID;
    # Drop privileges
    $UID  = $orig_uid;
    $GID  = $orig_gid;
    # Make sure privs are really gone
    ($EUID, $EGID) = @temp;
    die "Can't drop privileges"  unless $UID == $EUID  && $GID eq $EGID;
    $ENV{PATH} = "/bin:/usr/bin"; # Minimal PATH.
    # Consider sanitizing the environment even more.
    exec(@cmd) or die "can't exec myprog: $!";
    }
  }

sub cluster_queues {
  my $string = `qstat -xml -g c`;
  my $p = new XML::Parser(Style => 'Tree');
  my $tree = $p->parse($string);
  my @cqueues = grep {ref eq 'ARRAY'} @{$tree->[1]};
  for(@cqueues){
    my $hash;
    my $key;
    for(@$_){
      if(ref eq 'ARRAY'){
        $hash->{$key} = $_->[2];
        }
      elsif(not(ref) and $_ =~ /\w+/){
        $key = $_;
        }
      }
    $_ = $hash;
    }
  return @cqueues;
  }

sub joblist {
  my @options;
  for(@_){
    push @options, split(/\s+/);
    }
  push(@options, '-u \*') unless @options;
  my $options = join(' ', @options);
  my $string = `qstat -xml $options`;
  $string =~ s/\n//gs;
  $string =~ s/<[\/]*queue_info>//g;
  $string =~ s/<[\/]*job_info>//g;
  $string .= '</job_info>';
  my $p = new XML::Parser(Style => 'Tree');
  my $tree = $p->parse($string);
  my $items = $tree->[1];
  my @jobs;
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

    my @tasks = expand_sge_tasks($hash{tasks});
    if(@tasks){ # expand array jobs
      for(@tasks){
        push @jobs, {%hash, tasks => $_, JB_job_number=>"$hash{JB_job_number}.$_"};
        }
      next;
      }

    $hash{JB_job_number} = "$hash{JB_job_number}.$hash{tasks}" if $hash{tasks};
    if( @jobs and $jobs[-1]->{JB_job_number} eq $hash{JB_job_number}){
      next if $jobs[-1]->{slots}++ == 1; # don't include the SLAVE host that's also the MASTER
      push @{ $jobs[-1]->{hosts} }, $host;
      }
    else{
      $hash{hosts} = [$host] if defined $host;
      push @jobs, \%hash;
      }

    }
  for(@jobs){ # subtract 1 slot for parallel jobs because the master slot shouldn't be counted
    my $hosts = $_->{hosts} || [];
    # don't subtract for job listings that didn't use "-g t" (instances weren't expanded)
    next if $_->{slots} > 1 and @$hosts == 1;
    # don't subtract for single processor jobs
    next if $_->{slots} == 1;
    $_->{slots} -= 1;
    }
  return @jobs if wantarray;
  return \@jobs;
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

sub userinfo {
  my ($user, @req) = @_;
  db() unless defined $db;
  my $hash = $db->selectrow_hashref('select u.username,uid,g.groupname,gid FROM users u JOIN memberships m JOIN groups g ON u.username=m.username AND m.groupname=g.groupname WHERE u.username=? AND prime=1', undef, $user);
  return map {$hash->{$_}} @req;
  }

sub ipaddr { # convert integer to ip address
  my $num = shift;
  return unless defined $num;
  return join('.', i2addr(3, $num));
  }

sub macaddr { # convert integer to mac address
  return join(':', map {lc sprintf('%02x',$_)} i2addr(5,shift || 0));
  }

sub i2addr { # convert integer to decimal octet
  my ($max, $int) = @_;
  return unless defined $max and defined $int;
  return map {($int >> 8*$_) % 256} reverse (0..$max);
  }

sub addr2i {
  my $addr = shift;
  my @parts = split(/[:.]/, $addr);
  if(@parts == 6){ # is a MAC address
    @parts = map {hex} @parts;
    }
  my $mult = 0;
  my $sum = 0;
  for(reverse @parts){
    $sum += $_*256**$mult++;
    }
  return $sum;
  }

sub WebDB { # Get data from the newton.utk.edu user's database
  my $table = shift;
  my $raw = get("https://newton.utk.edu/manager/export?key=newton\&table=$table");
  return thaw($raw);
  }

sub selectall_arrayref { WebQuery(@_) }
sub fetchall_hashref { WebQuery(@_) }
sub selectrow_array { WebQuery(@_) }
sub selectcol_arrayref { WebQuery(@_) }

sub selectall_hash {
  my $data = selectall_arrayref(@_);
  return map {$_->[0]=>$_->[1]} @$data;
  }

sub WebQuery { # Get data from the newton.utk.edu database
  my ($sql, @vars) = map {uri_escape($_)} @_;
  # Create the SQL if the argument is only the table name
  $sql = "SELECT * FROM $sql" if $sql =~ /^\w+$/;
  # Encode the placeholder values into query string 
  my $vars = join(';', map {"v=$_"} @vars);
  # Encrypt the secret key and URL escape it
  my $hash = uri_escape md5_base64('newton', time);
  # Determine the SQL query method to use (DBI method)
  my ($method) = (caller(1))[3] =~ /::(.+?)$/;
  # Make the web request
  my $raw = get("https://newton.utk.edu/manager/query?key=$hash;method=$method;sql=$sql;$vars");
  my $out = thaw($raw);
  die "Error getting data in WebQuery" unless defined $out;
  return $out if $method =~ /ref$/;
  return @$out;
  }

sub bmc_passwd {
  my $cmd = $ENV{USER} eq 'root' ? 'cat' : 'sudo cat';
  my $dir = basedir();
  open(IN, "$cmd $dir/secrets |") or die $!;
  my ($passwd) = map {$_->[1]} 
                 grep {$_->[0] eq 'ipmipasswd'} 
                 map {[split /\s+/]} (<IN>);
  close IN;
  return $passwd;
  }

sub add_address {
  my ($name, $ip, $mac, $type, $system) = @_;
  my $db = db();
  my ($system_exists) = $db->selectrow_array('SELECT name FROM systems WHERE name=?', undef, $system);
  $db->do(
    'INSERT INTO addresses (name,ip,mac,type) VALUES (?,?,?,?)',
    undef, $name, addr2i($ip), addr2i($mac), $type,
    );
  unless(defined $system_exists){
    $db->do('INSERT INTO systems (name) VALUES (?)', undef, $name);
  }
  $db->do('UPDATE addresses SET system=? WHERE name=?', undef, $system, $name);
  }

sub sudo {
  my @args = @_ ? @_ : @ARGV;
  return if $ENV{USER} eq 'root';
  warn "Changing to root user ...\n";
  system('sudo', '-i', $0, @args);
  exit;
  }

sub node_install {
  node_install_dnsmasq();
  node_install_pxe();
  node_install_nagios();
  #Newton::Slurm::create_config('/etc/slurm/cluster.conf');
  # Nagios
  # Ganglia
  }

sub node_install_dnsmasq {
  # Rebuild all files that depend on cluster node information
  # DNS / DHCP
  my @nodes = nodes(type=>'system');
  my @bmc = nodes(type=>'bmc');
  my ($fh, $tempfile) = tempfile();
  for(@nodes, @bmc){
    print $fh "dhcp-host=$_->{mac},$_->{name},$_->{ip}\n";
    }
  close $fh;
  `sudo mv $tempfile /etc/dnsmasq.d/nodes.conf`;
  `sudo systemctl restart dnsmasq`;
}

sub node_install_pxe {
  my $basedir = basedir();
  my @nodes = nodes(type=>'system');
  for(@nodes){
    my $node = $_->{name};
    my $role = $_->{role} || '';
    my ($base) = split(/\s+/, $role);
    $base ||= '';
    my $hash = md5_hex($role);
    my $config = "${basedir}nodes/$base/images/$hash/config.ipxe";
    unless(defined($base) and -e $config){
      warn "Warning: Node role '$role' not found for node '$node'!\n";
      next;
      }
    $_->{mac} =~ s/://g;
    my $link = "$basedir/nodes/roles/" . lc($_->{mac});
    `ln -sf $config $link`;
    }
  }

sub node_install_nagios {
  my $basedir = basedir();
  my $db = db();
  my $hosts = $db->selectall_arrayref(
  'SELECT a.name,ip,nodeset,a.type,parent FROM addresses a JOIN systems s ON a.system=s.name'
  );
  my (%check, %allsets, @out);
  for(@$hosts){
    my ($name, $ip, $set, $type, $parent) = @$_;
    $set ||= 'other';
    $allsets{$set}++;
    $allsets{$type}++;
    if( $check{$name}++ ){
      warn "Dup: $name\n";
      $name = "$name-dup$check{$name}";
      }
    push @out, {
	  name => $name,
	  ip => Newton::ipaddr($ip),
	  parent => $parent,
	  notifications_enabled => ($type ne 'bmc')?1:0,
	  hostgroups => "$set,$type",
          };
  }
  my ($fh, $tempfile) = tempfile();
  tmpl(
	  "${basedir}scripts/tmpl/nagios_hosts.cfg",
	  $tempfile,
	  hosts => \@out,
	  groups => [map {{name=>$_}} keys %allsets],
  );
  `sudo cp $tempfile ${basedir}containers/nagios/conf.d/nodes.cfg`;
  `sudo killall -s HUP nagios`;
  }

1;


