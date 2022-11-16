#!/usr/bin/perl -w

#
# colorquestasim
#
# Version: 0.0.0
#
#
# A wrapper to colorize the output from Mentor Graphics QuestaSim messages.
#
#
# Usage: see at README.md
#
#
# Author: Yuriy Gritsenko <yuravg@gmail.com>
# URL: https://github.com/yuravg/color_questasim
# License: MIT License
#

use warnings;
use strict;

use List::Util 'first';
use IPC::Open3 'open3';
use File::Basename 'fileparse';
use File::Spec '';
use Cwd 'abs_path';
use Term::ANSIColor 'color';


my(%nocolor, %colors, %cmdPaths);

sub init_defaults
{
    $nocolor{"dumb"} = "true";

    $colors{"warningHeadColor"}     = color("yellow");
    $colors{"warningFileNameColor"} = color("cyan");
    $colors{"warningLineNumColor"}  = color("cyan");

    $colors{"errorHeadColor"}       = color("red");
    $colors{"errorFileNameColor"}   = color("cyan");
    $colors{"errorLineNumColor"}    = color("cyan");
}

sub load_configuration
{
    my $file_name = shift;
    my $fh;
    open($fh, "<", $file_name) or return;

    while (<$fh>) {
        next if (m/^\#.*/);         # It's a comment.
        next if (!m/(.*):\s*(.*)/); # It's not of the form "foo: bar".

        my $option = $1;
        my $value = $2;

        if ($option eq "nocolor") {
            # The nocolor option lists terminal types, separated by
            # spaces, not to do color on.
            foreach my $term (split(' ', $value)) {
                $nocolor{$term} = 1;
            }
        } elsif (defined $colors{$option}) {
            $colors{$option} = color($value);
        } else {
            $cmdPaths{$option} = $value;
        }
    }
    close($fh);
}

# From: https://github.com/colorgcc/
sub unique
{
    my %seen = ();
    grep {! $seen{$_ }++} @_;
}

sub can_execute
{
    warn "$_ is found but is not executable; skipping." if -e !-x;
    -x
}

# inspired from Thierry's snippet (Tve, 4-Jul-2002)
# http://www.tek-tips.com/viewthread.cfm?qid=305851
sub find_path
{
    my $program = shift;
    my $program_path = $0;

    # Load the path
    my @path = File::Spec->path();

    # join paths with program name and get absolute path
    @path = unique map {grep defined($_), File::Spec->join($_, $program)} @path;

    # Find first file spec in paths, that is not current program's file spec; is executable
    return first {$_ ne $program_path and can_execute($_)} @path;
}

#
# Main program
#

init_defaults();

my $prog_name = fileparse $0;

my $config_file = $ENV{"HOME"} . "/.colorquestasim";
if (-f $config_file) {
    load_configuration($config_file);
}
my $os_type = lc("$^O");
my $config_file_os = $ENV{"HOME"} . "/.colorquestasim" . "_$os_type";
if (-f $config_file_os) {
    load_configuration($config_file_os);
}

my $cmd = $cmdPaths{$prog_name} || find_path($prog_name);

my $terminal = $ENV{"TERM"} || "dumb";

# If it's in the list of terminal types not to color - don't do color.
if ($nocolor{$terminal}) {
    exec $cmd, @ARGV
        or die("Couldn't exec");
}

my $output;
my $cmd_pid = open3('<&STDIN', $output, '>&STDERR', $cmd, @ARGV);

while (<$output>) {
    # 'vlog' messages:
    # "** Error: (vlog-Num) file_name.sv(LineNum): Message."
    # "** Error: file_name.sv(LineNum): (vlog-Num) Message."
    # "** Error (Note): file-name.sv(LineNum): (vlog-Num) Message."
    if (/(^\*\*\s+)
         # Title
         (Error|Warning)
         (\s+\([^)]+\))?
         (:\s+)
         (\([^)]+\)\s+)?
         # File name
         ([A-z0-9._\/-]+)
         # Line number
         (\()([0-9]+)(\))
         # Message
         (:.*)$/x) {
        my $field1   = $1 || "";
        my $field2   = $2 || "";
        my $field3   = $3 || "";
        my $field4   = $4 || "";
        my $field5   = $5 || "";
        my $field6   = $6 || "";
        my $field7   = $7 || "";
        my $field8   = $8 || "";
        my $field9   = $9 || "";
        my $field10  = $10 || "";
        my $error_type = $field2 eq "Error";

        print $field1;
        if ($error_type) {
            print($colors{"errorHeadColor"}, "$field2", color("reset"));
        } else {
            print($colors{"warningHeadColor"}, "$field2", color("reset"));
        }
        print $field3, $field4, $field5;
        if ($error_type) {
            print($colors{"errorFileNameColor"}, "$field6", color("reset"));
        } else {
            print($colors{"warningFileNameColor"}, "$field6", color("reset"));
        }
        print $field7;
        if ($error_type) {
            print($colors{"errorLineNumColor"}, "$field8", color("reset"));
        } else {
            print($colors{"warningLineNumColor"}, "$field8", color("reset"));
        }
        print $field9, $field10, "\n";
    } elsif (/(^Errors:\s+)
              ([0-9]+)
              (,\s+)
              (Warnings:\s+)
              ([0-9]+)
              # To support MinGW only:
              (\s*)
              $
             /x) {
        # 'vlog' messages:
        # "Errors: Num, Warnings: Num"
        my $field1    = $1 || "";
        my $error_num = int($2) || 0;
        my $field3    = $3 || "";
        my $field4    = $4 || "";
        my $warning_num  = int($5) || 0;
        if ($error_num > 0) {
            print($colors{"errorHeadColor"}, "${field1}$error_num", color("reset"));
        } else {
            print $field1, $error_num;
        }
        print $field3;
        if ($warning_num > 0) {
            print($colors{"warningHeadColor"}, "${field4}$warning_num", color("reset"));
        } else {
            print $field4, $warning_num;
        }
        print "\n";
    } elsif (/(^\*\*\s+)
              # Title
              (Error)
              (:)?
              (\s+\([^)]+\))
              (:)?
              (.*)$/x) {
        # 'vopt' message
        # "** Error (Note): (vopt-Num) Message."
        # "** Error: (vopt-Num) Message."
        my $field1   = $1 || "";
        my $field2   = $2 || "";
        my $field3   = $3 || "";
        my $field4   = $4 || "";
        my $field5   = $5 || "";
        my $field6   = $6 || "";

        print $field1;
        print($colors{"errorHeadColor"}, "$field2", color("reset"));
        print $field3, $field4, $field5, $field6, "\n";
    } elsif (/^(No such file or directory.*)$/) {
        print($colors{"errorHeadColor"}, $1, color("reset"), "\n");
    } elsif (/^(Optimization failed*)$/) {
        print($colors{"errorHeadColor"}, $1, color("reset"), "\n");
    } else {
        print;
    }
}


if ($cmd_pid) {
    waitpid($cmd_pid, 0);
    exit ($? >> 8);
}
