#!/usr/bin/env perl
# PODNAME: newfix.pl
# ABSTRACT: trigger saxon on newfix easily

=head1 USAGE

newfix.pl source.mpx

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use FindBin;
use YAML::Syck qw(LoadFile);
use Cwd;
use File::Spec;

sub debug;

my $homedir = Cwd::realpath("$FindBin::Bin/..");
my $conf = File::Spec->catfile( $homedir, 'config.yml' );

#
# CONFIG AND COMMAND LINE SANITY
#

if ( !-f $conf ) {
	print "Error: Configuration not found (at $conf)!\n";
	exit 1;
}

my $config = LoadFile ($conf);
#use Data::Dumper qw/Dumper/;
#print Dumper $config;

debug "Debug mode (more verbose)";

if ( !$ARGV[0] ) {
	print "Error: Need an mpx file to work on!\n";
	exit 1;
}

if ( ! -f $ARGV[0] ) {
	print "Error: mpx input file not found!\n";
	exit 1;
}


required_config( $config, 'saxon', 'java', 'logfile', 'output', 'xsl' );

my $log    = File::Spec->catfile( $homedir, $config->{logfile} );
my $output = File::Spec->catfile( $homedir, $config->{output} );
my $xsl    = cyg2win( $config->{xsl} );
die "no xsl" if (!$xsl);
#
# MAIN
#

my $cmd = $config->{java} . ' -jar \'' . $config->{saxon}.'\' ';
$cmd .= "-s:$ARGV[0] ";
$cmd .= "-xsl:'$xsl' ";    #must win path
$cmd .= "-o:'$output' ";
$cmd .= "2>'$log'";

debug "\tDEBUG: about to execute:\n".$cmd;

system($cmd);

if ( $? == -1 ) {
        die "Error: failed to execute system: $!\n";
} elsif ( $? & 127 ) {
        printf "saxon died with signal %d, %s coredump\n", ( $? & 127 ),
          ( $? & 128 ) ? 'with' : 'without';
} else {
        printf "saxon exited with value %d\n", $? >> 8;
}

#
# SUBS
#

=func required_config ($hashref,$keyFirst .. $keyLast);

If a key does not exist in hashref, error message printed to STDOUT and
script ends with exit 1.

=cut

sub required_config {
	my $hashref = shift;

	foreach my $key (@_) {
		if ( !$hashref->{$key} ) {
			print "Error: Configuration key $key is missing\n";
			exit 1;
		}
	}
	#never sure how to return success
	return 0;
}

=head2 cyg2win

=cut

sub cyg2win {
	my $nix = shift;
	if (!$nix) {
		die "cyg2win called without path";
	}
	my $win = `cygpath -wa $nix`;
	$win =~ s/\s+$//;
	#debug "cygwin $nix -> $win";
	return $win;
}


=head2 my $win=nix2win($nix);

Quick, dirty and fast!

I eliminate trailing slash.

Copied from mpx-rif's MIMO.pm. Doesn't work if
path is inside cyghome.

=cut

sub nix2win {
	my $nix = shift;

	debug "Enter nix2win: $nix";
	$nix=File::Spec->rel2abs( $nix ) ;
	debug "abs:$nix";

	$nix =~ m!^/cygdrive/(\w+)/(.*)[/|]!;
	my $drive = $1 if $1;
	my $path  = $2 if $2;
	if ( $path && $drive ) {
		$path =~ s!/!\\!g;
		my $win = "$drive:\\$path";

		debug "cyg2win: $win";
		return $win;
	}


}

sub debug {
	my $msg=shift;
	#$config->{debug}=0 if (! $config->{debug})
	print "$msg\n" if ($msg &&$config->{debug});
}
