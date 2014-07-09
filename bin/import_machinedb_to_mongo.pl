#!/usr/local/bin/perl -w
# PODNAME: import_machinedb_to_mongo.pl
# ABSTRACT: Script that loads ImportFlatfilesToMongo.pm and runs it.
use strict;
use warnings;

use Carp;
use Getopt::Long;
Getopt::Long::Configure qw/bundling no_ignore_case/;
use Data::Dumper;
# Some Data::Dumper settings:
local $Data::Dumper::Useqq  = 1;
local $Data::Dumper::Indent = 3;
use Pod::Usage;
use Time::HiRes qw( gettimeofday );

use lib './lib/';
use ImportFlatfilesToMongo;

my $start = gettimeofday();

local $| = 1;

my $mydebug = 0;
my $dryrun  = 0;

GetOptions(
    "help|h"         => sub { pod2usage( 1 ); },
    "debug|d"        => \$mydebug,
    "dryrun|n"       => sub { $dryrun = 1; },
);

my $prog = $0;
$prog =~ s/^.*\///;

my $importer = ImportFlatfilesToMongo->new( debug => $mydebug,dryrun => $dryrun );

$importer->import_flatfiles();

END{
    if ( $mydebug ){
        my $prog = $0; 
        $prog =~ s/^.*\///;
        my $runTime = gettimeofday() - $start;
        print "$prog ran for ";
        if ( $runTime < 60 ){
            print "$runTime seconds.\n";
        } else {
            use integer;
            print $runTime / 60 . " minutes " . $runTime % 60
                . " seconds ($runTime seconds).\n";
        }
    }   
}

__END__

