#!/usr/bin/perl -w

use strict;
use warnings;
use POSIX qw(strftime);
use Text::CSV;
use Getopt::Long;
use Pod::Usage;

my $user;
my $weight;
my $opt_help; 
my $opt_man;

GetOptions(
    "user=s"     => \$user,     # string
    "weight=i"   => \$weight,   # numeric
    'help'       => \$opt_help,
    'man'        => \$opt_man,
) or pod2usage( "Try '$0 --help' for more information." );

pod2usage( -verbose => 1 ) if $opt_help;
pod2usage( -verbose => 2 ) if $opt_man;

unless( defined $user and defined $weight ) {
    pod2usage( "Try perl $0 -u <user name> -w <weight>" );
}

my $dir = 'weight_history_reports';

if( !( -e $dir and -d $dir ) )
{
    unless( mkdir $dir ) {
        die "Unable to create $dir\n";
    }
}

my $weight_dir = 0;
my $timestamp  = strftime("%Y-%m-%d_%H-%M-%S", localtime );
my $basename   = 'weight_history_report';
my $file_name  = "${user}_${basename}_${timestamp}";
my $file       = "$dir/$file_name.csv";

my $old_file;
my $fh;
my @rows;
my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                or die "Cannot use CSV: ".Text::CSV->error_diag ();

opendir (DIR, $dir) or die $!;
while( my $cur_file = readdir( DIR ) )
{
    # We only want files
    next unless( -f "$dir/$cur_file" );

    # Use a regular expression to find weight_history_report files
    next unless( $cur_file =~ m/\weight_history_report/ );

    $old_file = $cur_file;
}

closedir( DIR );

my $previous_weight = 0;

if( defined( $old_file ) ) 
{
    open $fh, "<:encoding(utf8)", "$dir/$old_file" or die "$dir/$old_file: $!";

    while( my $row = $csv->getline( $fh ) )
    {
        # if row is numeric
        if( $row->[1] =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ )
        {
            $weight_dir = $weight - $row->[1];
            $previous_weight = $row->[1];
        }

        push @rows, $row;
    }

    # check if last parse or getline() hit the end Of the file
    $csv->eof or $csv->error_diag();
    close $fh;

    # Remove old file
    unlink "$dir/$old_file" or warn "Could not unlink $dir/$old_file: $!";
}
else
{
    # Define file worksheet header
    my $row;
    $row->[0] = 'Time';
    $row->[1] = 'Weight(lbs)';
    $row->[2] = 'Gain/Lose(lbs)';
    push @rows, $row;
}

# Insert new row
my $row;
$row->[0] = $timestamp;
$row->[1] = $weight;
$row->[2] = $weight_dir;
push @rows, $row;

$csv->eol( "\r\n" );
 
open $fh, ">:encoding(utf8)", "$file" or die "$file: $!";
$csv->print( $fh, $_ ) for @rows;
close $fh or die "$file: $!";

=head1 EXAMPLES

  The following is an example of this script:

 weight_history_report.pl -u user_1 -w 170

=cut

=head1 OPTIONS

=over 8

=item B<-u> or B<-user>
User name

=item B<-w> or B<-weight>
Weight

=item B<--help>
Show the brief help information.

=item B<--man>
Read the manual, with examples.

=back

=cut
