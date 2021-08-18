#!/usr/bin/perl

# yumgroups.pl - Used to create the 'yumgroups.xml' file for yum's groupupdate feature
# Use the --help flag for more information
# Jeff Sheltren <sheltren@cs.ucsb.edu>
# September 14, 2003
# Version 1.0


use File::Find;
use File::Basename;
use Getopt::Long;

my $version_string = 'yumgroups version 1.0';

# set up variables that may be read in via command line options
my @directories = ();
my $groupname = '';
my $groupid = '';
my $fullxml = '';
my $header = false;
my $footer = false;
my $needhelp = false;
my $version = false;

# parse the command line options
GetOptions('group|g=s' => \$groupname, 'id|i=s' => \$groupid, 'directory|d=s' => \@directories, 'comps|c' => \$header, 'footer|f' => \$footer, 'xml|x' => \$fullxml, 'help|h' => \$needhelp, 'version|v' => \$version);


# if help was specified, print usage message and exit
if($needhelp == 1) {
    &usage();
    exit;
}

# if version was specified, print version and exit
if($version == 1) {
    print STDERR "$version_string\n";
    exit;
}

# if only header or footer was specified, print that stuff out
if($footer == 1) {
    &print_footer();
    exit;
}

if($header == 1) {
    &print_header();
    exit;
}

# make sure that there is a groupname and groupid specified
if($groupname eq '' || $groupid eq '') {
    print STDERR "You must specify a group name and a group id\n";
    print STDERR "(using the --group and --id flags)\n";
    exit;
}


# if there was a directory specified
if($#directories >= 0) {
    find(\&getrpms, @directories);
}

# Add any command line arguments as packages as well 
foreach(@ARGV) {
    $index{$_}++;
}

# sort package names and get rid of duplicates
@pkgs = sort keys(%index);
$pkgcount = $#pkgs + 1;

if($pkgcount == 0) {
    print STDERR "No packages were found or specified on the command line.\n";
    exit;
}

if($fullxml == 1) {
    &print_header();
}
&output_group();
if($fullxml == 1) {
    &print_footer();
}

# some debugging stuff
# print STDERR "Found $pkgcount unique packages.\n";
#foreach $package (@pkgs) {
#    print STDERR "$package\n";
#}

sub getrpms {
    # skip over source rpms
    if($_ =~ /[sS][rR][cC]\.[rR][pP][mM]$/) {
        next;
    }
    # get the package name from the filename
    if($_ =~ /^(.*)-([^-]+)-([^-]+)\.[^.]+\.[rR][pP][mM]$/) { 
	$index{$1}++;
    }
}

sub usage {
    print STDERR "\nUsage:  ";
    print STDERR "$0 [options] [packagename packagename ...]\n\n\t";
    print STDERR "Options:\n\t ";
    print STDERR "[-g, --group <group name>]\n\t ";
    print STDERR "[-i, --id <group id>]\n\t ";
    print STDERR "[-c, --comps]  (print the comps XML header only)\n\t ";
    print STDERR "[-f, --footer] (print the XML footer only\n\t ";
    print STDERR "[-x, --xml] (print out XML header and footer as well as group data)\n\t ";
    print STDERR "[-h, --help] (print this help message)\n\t ";
    print STDERR "[-d --directory <directory>] (specify a directory for the script to\n\t ";
    print STDERR "recursively look through) - you can use multiple -d flags to specify more\n\t ";
    print STDERR "than one directory.\n\n\t";
    print STDERR "packagename is the name of an RPM package to be included in the group\n\n\t";
    print STDERR "If you specify a directory or a package name, then you MUST specify\n\t";
    print STDERR "a group name and group id.\n\n";
    print STDERR "Ex: $0 -g somegroup -i someid -d /ftp/repo1 -d /ftp/repo2 foo bar\n\t";
    print STDERR "will output the XML for group 'somegroup' including all RPMs in\n\t";
    print STDERR "/ftp/repo1 and /ftp/repo2 (as well as their sub-directories).\n\t";
    print STDERR "It will also include the packages 'foo' and 'bar' in the group.\n\n";

}

sub output_group {
    print "  <group>\n";
    print "   <id>$groupid</id>\n";
    print "   <uservisible>true</uservisible>\n";
    print "   <name>$groupname</name>\n";
    print "   <packagelist>\n";
    foreach(@pkgs) {
        print "     <packagereq type=\"mandatory\">$_</packagereq>\n";
    }
    print "   </packagelist>\n";
    print "  </group>\n";
}

sub print_header {
    print "<?xml version=\"1.0\"?>\n";
    print "<!DOCTYPE comps PUBLIC \"-//Red Hat, Inc.//DTD Comps info//EN\" \"comps.dtd\">\n";
    print "<comps>\n";
}

sub print_footer {
    print "</comps>\n";
}
