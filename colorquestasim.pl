#!/usr/bin/perl -w

#
# colorquestasim
#
# Version: 1.0.2
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
use feature 'state';


my(%nocolor, %colors, %cmd_paths, %vsim_cfg);

sub init_defaults
{
    $nocolor{"dumb"} = "true";

    $colors{"note_head_color"}        = color("blue");
    $colors{"note_fname_color"}       = color("cyan");
    $colors{"note_line_num_color"}    = color("cyan");
    $colors{"note_message_color"}     = color("clear");

    $colors{"warning_head_color"}     = color("yellow");
    $colors{"warning_fname_color"}    = color("cyan");
    $colors{"warning_line_num_color"} = color("cyan");
    $colors{"warning_message_color"}  = color("cyan");

    $colors{"error_head_color"}       = color("red");
    $colors{"error_fname_color"}      = color("cyan");
    $colors{"error_line_num_color"}   = color("cyan");
    $colors{"error_message_color"}    = color("cyan");

    $vsim_cfg{"show_vsim_copyright"} = "true";
    $vsim_cfg{"show_vsim_start_cmd"} = "true";
    $vsim_cfg{"show_vsim_start_time"} = "true";
}

sub load_configuration
{
    my $file_name = shift;
    open(my $fh, "<", $file_name) or return;

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
        } elsif (defined $vsim_cfg{$option}) {
            $vsim_cfg{$option} = "$value";
        } else {
            $cmd_paths{$option} = $value;
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

my $cmd = $cmd_paths{$prog_name} || find_path($prog_name);

my $terminal = $ENV{"TERM"} || "dumb";

# If it's in the list of terminal types not to color - don't do color.
if ($nocolor{$terminal}) {
    exec $cmd, @ARGV
        or die("Couldn't exec");
}

my $output;
my $cmd_pid = open3('<&STDIN', $output, $output, $cmd, @ARGV);

while (<$output>) {
    if ($prog_name eq "vlog" && vlog_scan($_)) {
    } elsif ($prog_name eq "vopt" && vopt_scan($_)) {
    } elsif ($prog_name eq "vsim" && vsim_scan($_)) {
    } else {
        print;
    }
}

if ($cmd_pid) {
    waitpid($cmd_pid, 0);
    exit ($? >> 8);
}


#
# Parsers
#

sub vlog_scan {
    if (/^(\*\*\s+)
         # Title
         (Error|Warning|Note)
         (\s+\([^)]+\))?
         (:\s+)
         (\([^)]+\)\s+)?
         # File name
         ([A-z0-9._\/-]+)
         # Line number and round brackets
         (\()([0-9]+)(\))
         (:)
         # vlog Num
         (\s+\([^)]+\))?
         # Message
         (.*)$/x) {
        # 'vlog' messages:
        # "** Error: (vlog-Num) FileName(LineNum): Message."
        # "** Error: FileName(LineNum): (vlog-Num) Message."
        # "** Error (Note): FileName(LineNum): (vlog-Num) Message."
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
        my $field11  = $11 || "";
        my $field12  = $12 || "";
        my $error_type = $field2 eq "Error";
        my $note_type = $field2 eq "Note";

        print $field1;
        if ($note_type) {
            print($colors{"note_head_color"}, "$field2", color("reset"));
        } elsif ($error_type) {
            print($colors{"error_head_color"}, "$field2", color("reset"));
        } else {
            print($colors{"warning_head_color"}, "$field2", color("reset"));
        }
        print $field3, $field4, $field5;
        if ($note_type) {
            print($colors{"note_fname_color"}, "$field6", color("reset"));
        } elsif ($error_type) {
            print($colors{"error_fname_color"}, "$field6", color("reset"));
        } else {
            print($colors{"warning_fname_color"}, "$field6", color("reset"));
        }
        print $field7;
        if ($note_type) {
            print($colors{"note_line_num_color"}, "$field8", color("reset"));
        } elsif ($error_type) {
            print($colors{"error_line_num_color"}, "$field8", color("reset"));
        } else {
            print($colors{"warning_line_num_color"}, "$field8", color("reset"));
        }
        print $field9, $field10, $field11;
        if ($note_type) {
            print($colors{"note_message_color"}, "$field12\n", color("reset"));
        } elsif ($error_type) {
            print($colors{"error_message_color"}, "$field12\n", color("reset"));
        } else {
            print($colors{"warning_message_color"}, "$field12\n", color("reset"));
        }
        1;
    } elsif (/^(\*\*\s+)
              (Error|Warning)
              (:\s+|\s+\(suppressible\):\s+)
              (\([^)]+\)\s+)?
              (\*\*\s+while\s+parsing\s+file\s+included\s+at\s+)
              # File name
              ([A-z0-9._\/-]+)
              # Line number and round brackets
              (\()([0-9]+)(\))
              # Only for MinGW:
              (\s*)
              $/x) {
        # 'vlog' messages:
        # "** Error: (vlog-Num) ** while parsing file included at FileName(LineNum)"
        # "** Error (suppressible): ** while parsing file included at FileName(LineNum)"
        # "** Error: ** while parsing file included at FileName(LineNum)"
        # "** Warning: ** while parsing file included at FileName(LineNum)"
        my $field1   = $1 || "";
        my $field2   = $2 || "";
        my $field3   = $3 || "";
        my $field4   = $4 || "";
        my $field5   = $5 || "";
        my $field6   = $6 || "";
        my $field7   = $7 || "";
        my $field8   = $8 || "";
        my $field9   = $9 || "";
        my $error_type = $field2 eq "Error";
        print $field1;
        if ($error_type) {
            print($colors{"error_head_color"}, "$field2", color("reset"));
        } else {
            print($colors{"warning_head_color"}, "$field2", color("reset"));
        }
        print $field3, $field4;
        if ($error_type) {
            print($colors{"error_message_color"}, "$field5", color("reset"));
        } else {
            print($colors{"warning_message_color"}, "$field5", color("reset"));
        }
        if ($error_type) {
            print($colors{"error_fname_color"}, "$field6", color("reset"));
        } else {
            print($colors{"warning_fname_color"}, "$field6", color("reset"));
        }
        print $field7;
        if ($error_type) {
            print($colors{"error_line_num_color"}, "$field8", color("reset"));
        } else {
            print($colors{"warning_line_num_color"}, "$field8", color("reset"));
        }
        print $field9, "\n";
        1;
    } elsif (/^(\*\*\s+)
              (at\s+)
              # File name
              ([A-z0-9._\/-]+)
              # Line number and round brackets
              (\()([0-9]+)(\))
              (:)
              # Message
              (.*)
              $/x) {
        # 'vlog' message:
        # "** at FileName(LineNum): Message.
        my $field1   = $1 || "";
        my $field2   = $2 || "";
        my $field3   = $3 || "";
        my $field4   = $4 || "";
        my $field5   = $5 || "";
        my $field6   = $6 || "";
        my $field7   = $7 || "";
        my $field8   = $8 || "";
        print $field1;
        print($colors{"error_message_color"}, "$field2", color("reset"));
        print($colors{"error_fname_color"}, "$field3", color("reset"));
        print $field4;
        print($colors{"error_line_num_color"}, "$field5", color("reset"));
        print $field6, $field7;
        print($colors{"error_message_color"}, "$field8\n", color("reset"));
        1;
    } elsif (/^(Errors:\s+)
              ([0-9]+)
              (,\s+)
              (Warnings:\s+)
              ([0-9]+)
              # Only for MinGW:
              (\s*)
              $/x) {
        # 'vlog' messages:
        # "Errors: Num, Warnings: Num"
        my $field1    = $1 || "";
        my $error_num = int($2) || 0;
        my $field3    = $3 || "";
        my $field4    = $4 || "";
        my $warning_num  = int($5) || 0;
        if ($error_num > 0) {
            print($colors{"error_head_color"}, "${field1}$error_num", color("reset"));
        } else {
            print $field1, $error_num;
        }
        print $field3;
        if ($warning_num > 0) {
            print($colors{"warning_head_color"}, "${field4}$warning_num", color("reset"));
        } else {
            print $field4, $warning_num;
        }
        print "\n";
        1;
    } else {
        0;                      # no matches found
    }
}

sub vopt_scan {
    if (/^(\*\*\s+)
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
        print($colors{"error_head_color"}, "$field2", color("reset"));
        print $field3, $field4, $field5, $field6, "\n";
        1;
    } elsif (/^(\*\*\s+)
              # Title
              (Note)
              (:)
              (.*)$/x) {
        # 'vopt' message
        # "** Note: Message"
        my $field1   = $1 || "";
        my $field2   = $2 || "";
        my $field3   = $3 || "";
        my $field4   = $4 || "";
        print $field1;
        print($colors{"note_head_color"}, "$field2", color("reset"));
        print $field3;
        print($colors{"note_message_color"}, "$field4", color("reset"));
        print "\n";
        1;
    } elsif (/^(No such file or directory.*)$/) {
        print($colors{"error_head_color"}, $1, color("reset"), "\n");
        1;
    } elsif (/^(Optimization failed*)$/) {
        print($colors{"error_head_color"}, $1, color("reset"), "\n");
        1;
    } else {
        0;                      # no matches found
    }
}

sub vsim_scan {
    state $copyright_scan = $vsim_cfg{"show_vsim_copyright"} ne "true";
    state $copyrigth_detect = 0;

    if ($copyright_scan) {
        # Abort scanning of the copyright message and enable next scan
        # Error message *without* show copyright message
        # 'vsim' message:
        # "** Error Message.
        if (/\#\s+\*\*\s+Error/) {
            $copyright_scan = 0;
        }
        # End of copyright message
        if ($copyrigth_detect && not /^#\s+\/\//) {
            $copyright_scan = 0;
        }
    }

    if ($copyright_scan) {
        if (/^\#\s+vsim\s+.*$/ &&
            $vsim_cfg{"show_vsim_start_cmd"} eq "true") {
            print;
        }
        if (/^\#\s+Start\s+.*$/ &&
            $vsim_cfg{"show_vsim_start_time"} eq "true") {
            print;
        }
        # Wait start of copyright message: '# // ', then wait its end
        if (/^#\s+\/\/\s+$/) {
            $copyrigth_detect = 1;
        }
        1;
    } elsif (/^(\#\s+\*\*\s+)
              # Title
              (Error)
              (\s+\([^)]+\))?
              (:\s+)
              (\([^)]+\)\s+)?
              # File name
              ([A-z0-9._\/-]+)
              # Line number and round brackets
              (\()([0-9]+)(\))
              (:)
              # vlog Num
              (\s+\([^)]+\))?
              # Message
              (.*)$/x) {
        # 'vsim' messages:
        # "** Error: (vlog-Num) FileName(LineNum): Message."
        # "** Error: FileName(LineNum): (vlog-Num) Message."
        # "** Error (Note): FileName(LineNum): (vlog-Num) Message."
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
        my $field11  = $11 || "";
        my $field12  = $12 || "";

        print $field1;
        print($colors{"error_head_color"}, "$field2", color("reset"));
        print $field3, $field4, $field5;
        print($colors{"error_fname_color"}, "$field6", color("reset"));
        print $field7;
        print($colors{"error_line_num_color"}, "$field8", color("reset"));
        print $field9, $field10, $field11;
        print($colors{"error_message_color"}, "$field12\n", color("reset"));
        1;
    } elsif (/^(\#\s+\*\*\s+)
              # Title
              (Fatal:|Error:|Warning:|Note:|Info:)
              # Message
              (.*)/x) {
        # 'vsim' messages:
        # "# ** Error: Message"
        my $field1   = $1 || "";
        my $field2   = $2 || "";
        my $field3   = $3 || "";
        my $warning_type = $field2 eq "Warning:";
        my $note_type = $field2 eq "Note:" || $field2 eq "Info:";

        print $field1;
        if ($note_type) {
            print($colors{"note_head_color"}, "$field2", color("reset"));
        } elsif ($warning_type) {
            print($colors{"warning_head_color"}, "$field2", color("reset"));
        } else {
            print($colors{"error_head_color"}, "$field2", color("reset"));
        }
        if ($note_type) {
            print($colors{"note_message_color"}, "$field3", color("reset"));
        } elsif ($warning_type) {
            print($colors{"warning_message_color"}, "$field3", color("reset"));
        } else {
            print($colors{"error_message_color"}, "$field3", color("reset"));
        }
        print "\n";
        1;
    } elsif (/^(\#\s+)
              (Errors:\s+)
              ([0-9]+)
              (,\s+)
              (Warnings:\s+)
              ([0-9]+)
              # Only for MinGW:
              (\s*)
              $/x) {
        # 'vsim' messages:
        # "# Errors: Num, Warnings: Num"
        my $field1    = $1 || "";
        my $field2    = $2 || "";
        my $error_num = int($3) || 0;
        my $field4    = $4 || "";
        my $field5    = $5 || "";
        my $warning_num  = int($6) || 0;

        print $field1;
        if ($error_num > 0) {
            print($colors{"error_head_color"}, "${field2}$error_num", color("reset"));
        } else {
            print $field2, $error_num;
        }
        print $field4;
        if ($warning_num > 0) {
            print($colors{"warning_head_color"}, "${field5}$warning_num", color("reset"));
        } else {
            print $field5, $warning_num;
        }
        print "\n";
        1;
    } elsif (/^(#\s+)(Error loading design)$/) {
        my $field1    = $1 || "";
        my $field2    = $2 || "";
        print $field1;
        print($colors{"error_head_color"}, "$field2", color("reset"));
        print "\n";
        1;
    } else {
        0;                      # no matches found
    }
}
