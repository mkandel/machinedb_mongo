package ImportFlatfilesToMongo;
# ABSTRACT: Class that knows how to parse MachineDB files and insert the info into a MongoDB instance
use Data::Dumper;
# Some Data::Dumper settings:
local $Data::Dumper::Useqq  = 1;
local $Data::Dumper::Indent = 3;

use Carp;

use MongoDB;

local $| = 1; ## Unbuffered output

sub new {
    my ( $class, %params ) = @_;

    return bless \%params, $class;
}

sub import_flatfiles {
    my ( $self ) = @_;
    my $success = 1;

    use MongoDB;
    use Sys::Hostname;
    use File::Find::Rule;
    my $host = hostname;

    my $db_name   = 'machinedb';
    my $coll_name = 'machines';

    my $client = MongoDB::MongoClient->new;
    my $db = $client->get_database( $db_name );
    my $machines = $db->get_collection( $coll_name );

    ## Hand rolling a file logger for very specific reasons:
    my $logfile = '/var/log/ariba/machinedb/import.log';
    open my $LOG, '>>', $logfile or die "Couldn't open '$logfile' for write: $!\n";
    print $LOG "#######################################################################\n";
    print $LOG "Import run starting\n";

    unless ( $host =~ m/^mkandel-/ ){
        croak 'Called import_flatfiles on non-development machine, ignoring!!';
    }

    my $dir;
    if ( $host =~ m/mkandel-rh/ ){
        $dir    = '/home/mkandel/ariba/services/operations/machinedb';
    } else { ## mkandel-mac
        $dir    = '/Users/mkandel/ariba/services/operations/machinedb';
    }
    my @files  = File::Find::Rule->file()->in( $dir );
    print $LOG "File::Find::Rule found ", scalar @files, " machinedb files\n";

    ## Not sure why/what/how to get this to work ...
    #my $prefix = 'machine.';
    my $printed_filename;

    FILE:
    foreach my $file ( @files ){
        open my $IN, '<', $file or die "Couldn't open '$file' for read: $!\n";
        my $detail;
        my $hostname;

        $printed_filename = 0;
        print $LOG "** Processing '$file' ... **\n";
        LINE:
        while ( my $line = <$IN> ){
            next LINE if $line =~ m/^\s*$/; ## Ignore blank lines
            next LINE if $line =~ m/^#$/;   ## Ignore comments?
#            next LINE unless $column_for_field{ $field };

            my ( $field, $val ) = split /:/, $line;
            chomp $val if $val;
            $val =~ s/\s*//g if $val;   ## Remove whitespace
            $val = defined $val ? $val : '';

            if ( $field =~ /^hostname$/i ){
                $hostname = $val;
            }
#            print $LOG "\tkey: '$field'\t\tval: '$val'\n";

            $detail->{ "$field" } = $val;
        }
#        print $LOG Dumper $new;

        $machines->update( 
            { 'hostname' => $hostname },
            { '$set'     => $detail },
            { 'upsert'   => 1 }
        );

        close $IN or die "Error closing '$file' after read: $!\n";
    }

    print $LOG "Import complete!\n";
    close $LOG or die "Error closing '$logfile' after write: $!\n";
}
1;

__END__

=method new()

Creates an ImportFlatfilesToMongo object

=method import_flatfiles()

Gathers MachineDB info from the flatfiles in //ariba/services/operations/machinedb, parses them and inserts the data into a MongoDB instance

