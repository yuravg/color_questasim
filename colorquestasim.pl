#!/usr/bin/perl -w

#
# colorquestasim
#

use warnings;
use strict;
use constant VERSION => "1.2.15";

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

use List::Util qw(first);
use IPC::Open3 qw(open3);
use File::Basename qw(fileparse);
use File::Spec ();
use Term::ANSIColor qw(color);
use feature qw(state);
use constant {
    TRUE  => 1,
    FALSE => 0,
};

if (defined $ARGV[0] &&
    $ARGV[0] =~ /^(--version)$/) {
    print "colorquestasim ", VERSION, " $0\n" and exit;
}

if (defined $ARGV[0] &&
    $ARGV[0] =~ /^(--help)$/) {
    print_usage() and exit;
}

sub print_usage {
    my $prog_name = fileparse $0;
    print <<"END_USAGE";
Usage: $prog_name [$prog_name-options] [wrapper-options]

Description:
  colorquestasim is a wrapper script (used via a symbolic link)
  to colorize the output from Mentor Graphics QuestaSim messages.

$prog_name-Options:
  $prog_name specific options.
  For more information on these options, run: $prog_name -help

Wrapper-Options:
  --off, --disable      Do not do color and parsing $prog_name output
  --version             Display the script version and exit
  --help                Display this help message and exit
END_USAGE
}

my(%nocolor, %colors, %cmd_paths, %vsim_cfg, @vsim_hi_patterns);

sub init_defaults
{
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

    $vsim_cfg{"show_vsim_copyright"}    = TRUE;
    $vsim_cfg{"show_vsim_start_cmd"}    = TRUE;
    $vsim_cfg{"show_vsim_start_time"}   = TRUE;
    $vsim_cfg{"show_vsim_loading_libs"} = TRUE;

    $vsim_cfg{"show_vsim_uvm_relnotes"}  = TRUE;
    $vsim_cfg{"show_questa_uvm_pkg_rpt"} = TRUE;

    $vsim_cfg{"vsim_hi_patterns_en"} = FALSE;
}

sub set_logical_option
{
    my $ref = shift;
    $_ = shift;
    if (/^(true|yes)$/) {
        $$ref = TRUE;
    } elsif (/^(false|no)$/) {
        $$ref = FALSE;
    }
}

sub vsim_option_is_true
{
    return $vsim_cfg{$_[0]} ? TRUE : FALSE;
}

sub load_configuration
{
    my $file_name = shift;
    open(my $fh, "<", $file_name) or return;

    while (<$fh>) {
        next if (m/^\#.*/);     # It's a comment.
        # It is not one of the forms:
        # <option_name> : <value>
        # <option_name> : <value1> : <value2>
        next if (!m/(^[^:]+)\s*:\s*([^:\n]+)(:\s*(.*))?\s*\n/);

        my $option = $1;
        my $value = $2;
        my $mask = $4 || "";
        trim($option);
        trim($value);
        trim($mask);

        if ($option eq "nocolor") {
            # The nocolor option lists terminal types, separated by
            # spaces, not to do color on.
            foreach my $term (split(' ', $value)) {
                $nocolor{$term} = 1;
            }
        } elsif (defined $colors{$option}) {
            $colors{$option} = color($value);
        } elsif (defined $vsim_cfg{$option}) {
            set_logical_option(\$vsim_cfg{$option}, $value)
        } elsif (($option =~ /^vsim_hi_patterns$/) &&
                 $value ne "" &&
                 $mask ne "") {
            push(@vsim_hi_patterns, $mask, $value);
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

my $parsing_disable = 0;
my $regex_parsing_disable = qr/^--(off|disable)$/;

# Remove the 'colorquestasim' argument(s) from the list of command line arguments
@ARGV = grep {
    my $keep = !/$regex_parsing_disable/;
    $parsing_disable = 1 unless $keep;
    $keep;
} @ARGV;

# Do not color and parsing:
# - if it is in the list of terminal types that should not be colored
# - if the COLORQUESTASIM environment variable contains one of the values: off, disable
# - if the vlog/vopt/vsim commands are run with one of the arguments: --off --disable
if ($nocolor{$terminal} ||
    (defined $ENV{COLORQUESTASIM} && $ENV{COLORQUESTASIM} =~ /off|disable/) ||
    $parsing_disable) {
    exec $cmd, @ARGV
        or die("Couldn't exec");
}

my $output;
my $cmd_pid = open3('<&STDIN', $output, $output, $cmd, @ARGV);

while (<$output>) {
    # Remove the 0xOD character that is appended (?!) to the argument string
    # in the emacs terminal in Windows OS
    s/\x0D//g;

    if (defined $ARGV[0] &&
        $ARGV[0] =~ /^(-version|-h|-help)$/) {
        print;
    } elsif ($prog_name eq "vlog") {
        vlog_scan($_);
    } elsif ($prog_name eq "vopt") {
        vopt_scan($_);
    } elsif ($prog_name eq "vsim") {
        vsim_scan($_);
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

sub vlog_scan
{
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
        # "** Error (Note): FileName(LineNum): (vlog-Num) Message."
        # "** Error: FileName(LineNum): (vlog-Num) Message."
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
            print_color("note_head_color", "$field2");
        } elsif ($error_type) {
            print_color("error_head_color", "$field2");
        } else {
            print_color("warning_head_color", "$field2");
        }
        print $field3, $field4, $field5;
        if ($note_type) {
            print_color("note_fname_color", "$field6");
        } elsif ($error_type) {
            print_color("error_fname_color", "$field6");
        } else {
            print_color("warning_fname_color", "$field6");
        }
        print $field7;
        if ($note_type) {
            print_color("note_line_num_color", "$field8");
        } elsif ($error_type) {
            print_color("error_line_num_color", "$field8");
        } else {
            print_color("warning_line_num_color", "$field8");
        }
        print $field9, $field10, $field11;
        if ($note_type) {
            print_color("note_message_color", "$field12");
        } elsif ($error_type) {
            print_color("error_message_color", "$field12");
        } else {
            print_color("warning_message_color", "$field12");
        }
        print "\n";
    } elsif (/^(\*\*\s+)
              (Error|Warning)
              (:\s+|\s+\(suppressible\):\s+)
              (\([^)]+\)\s+)?
              (\*\*\s+while\s+parsing\s+(?:(?:file\s+included\s+at\s+)|(?:macro\s+.*\s+)))
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
        # "** Error: ** while parsing macro expansion: 'Name' starting at FileName(LineNum)"
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
            print_color("error_head_color", "$field2");
        } else {
            print_color("warning_head_color", "$field2");
        }
        print $field3, $field4;
        if ($error_type) {
            print_color("error_message_color", "$field5");
        } else {
            print_color("warning_message_color", "$field5");
        }
        if ($error_type) {
            print_color("error_fname_color", "$field6");
        } else {
            print_color("warning_fname_color", "$field6");
        }
        print $field7;
        if ($error_type) {
            print_color("error_line_num_color", "$field8");
        } else {
            print_color("warning_line_num_color", "$field8");
        }
        print $field9, "\n";
    } elsif (/^(\*\*\s+)
              # Title
              (Error)
              # Note
              (\s+\([^)]+\))
              (:\s+)
              # vlog Num
              (\([^)]+\))
              # Message
              (.*)$/x) {
        # 'vlog' message:
        # "** Error (Note): (vlog-Num) Option Message" - NOTE: 'vlog' command argument error message
        my $field1   = $1 || "";
        my $field2   = $2 || "";
        my $field3   = $3 || "";
        my $field4   = $4 || "";
        my $field5   = $5 || "";
        my $field6   = $6 || "";
        print $field1;
        print_color("error_head_color", "$field2");
        print $field3, $field4, $field5;
        print_color("error_message_color", "$field6");
        print "\n";
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
        print_color("error_message_color", "$field2");
        print_color("error_fname_color", "$field3");
        print $field4;
        print_color("error_line_num_color", "$field5");
        print $field6, $field7;
        print_color("error_message_color", "$field8");
        print "\n";
    } elsif (/^(\*\*\s+)
              (Fatal)
              (:.*)
             /x) {
        # 'vlog' message:
        # "** Fatal: Message"
        my $field1   = $1 || "";
        my $field2   = $2 || "";
        my $field3   = $3 || "";
        print $field1;
        print_color("error_head_color", "${field2}${field3}");
        print "\n";
    } elsif (/^(\*\*\s+)
              (Error)
              (:\s+)
              # vlog Num
              (\([^)]+\)\s+)?
              (.*)
             /x) {
        # 'vlog' message:
        # "** Error: (vlog-Num) Failed to open design unit file "FileName" in read mode."
        my $field1   = $1 || "";
        my $field2   = $2 || "";
        my $field3   = $3 || "";
        my $field4   = $4 || "";
        my $field5   = $5 || "";
        print $field1;
        print_color("error_head_color", "$field2");
        print $field3, $field4;
        print_color("error_message_color", "$field5");
        print "\n";
    } elsif (/^(No\s+such\s+file\s+or\s+directory.*)
             /x) {
        # 'vlog' message:
        # No such file or directory. (errno = ENOENT)
        my $field1   = $1 || "";
        print_color("error_message_color", "$field1");
        print "\n";
    } elsif (error_summary_parser($_)) {
    } else {
        print;                  # Nothing found. Print current line without changes.
    }
}                               # vlog_scan

sub vopt_scan
{
    if (/^(\*\*\s+)
         # Title
         (Error|Warning)
         (:\s+|\s+\(suppressible\):\s+)
         (?:
             # File name
             ([A-z0-9._\/-]+)
             # Line number and round brackets
             (\()([0-9]+)(\))
             (:\s+)
         )?
         # vopt-Num
         (\([^)]+\))?
         # Message
         (.*)$/x) {
        # 'vlog' messages:
        # "** Error: FileName(LineNum): Message."
        # "** Warning: FileName(LineNum): (vopt-Num) Message."
        # "** Error: (vopt-Num) Message."
        # "** Error (suppressible): FileName(LineNum): (vopt-Num) Message."
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
            print_color("error_head_color", "$field2");
        } else {
            print_color("warning_head_color", "$field2");
        }
        print $field3;
        if ($error_type) {
            print_color("error_fname_color", "$field4");
        } else {
            print_color("warning_fname_color", "$field4");
        }
        print $field5;
        if ($error_type) {
            print_color("error_line_num_color", "$field6");
        } else {
            print_color("warning_line_num_color", "$field6");
        }
        print $field7, $field8, $field9;
        if ($error_type) {
            print_color("error_message_color", "$field10");
        } else {
            print_color("warning_message_color", "$field10");
        }
        print "\n";
    } elsif (/^(\*\*\s+)
              # Title
              (Note)
              (:)
              (.*)$/x) {
        # 'vopt' message:
        # "** Note: Message"
        my $field1   = $1 || "";
        my $field2   = $2 || "";
        my $field3   = $3 || "";
        my $field4   = $4 || "";
        print $field1;
        print_color("note_head_color", "$field2");
        print $field3;
        print_color("note_message_color", "$field4");
        print "\n";
    } elsif (/^(No such file or directory.*)$/) {
        print_color("error_head_color", $1, color);
    } elsif (/^(\s+For instance.*)$/) {
        # 'vopt' message:
        # For instance 'InstanceName' at path 'FullPath.InstanceName'
        print_color("warning_message_color", $1, color);
    } elsif (/^(Optimization failed.*)$/) {
        print_color("error_head_color", "$1");
        print "\n";
    } elsif (error_summary_parser($_)) {
    } else {
        print;                  # Nothing found. Print current line without changes.
    }
}                               # vopt_scan

sub vsim_scan
{
    state $copyright_scan = not vsim_option_is_true("show_vsim_copyright");
    state $copyrigth_detected = 0;
    state $run_do_file = 0;
    state $loading_scan = not vsim_option_is_true("show_vsim_loading_libs");
    state $uvm_relnotes_scan = not vsim_option_is_true("show_vsim_uvm_relnotes");
    state $uvm_relnotes_detected = 0;
    state $uvm_relnotes_msg_detected = 0;
    state $questa_uvm_pkg_scan = not vsim_option_is_true("show_questa_uvm_pkg_rpt");

    # Abort scanning of the Copyright message:
    if ($copyright_scan) {
        # Abort scanning of the copyright message and enable next scan
        # Error message *without* show copyright message
        # 'vsim' message:
        # "** Error Message.
        if (/\#\s+\*\*\s+Error/) {
            $copyright_scan = 0;
        }
        # Run do file (run like: vsim -c -do run.do)
        if (/^#\s+do\s+/) {
            $run_do_file = 1;
        }
        # End of the copyright message:
        # Message without "# //"
        if ($copyrigth_detected && not /^#\s+\/\//) {
            $copyright_scan = 0;
        }
    }

    # Start/Abort scanner of the UVM release note
    if ($uvm_relnotes_scan) {
        # Start of the UVM release notes: '# UVM_INFO ...'
        if (/\#\s+UVM_INFO\s+/) {
            if ($uvm_relnotes_detected ||
                /\#\s+UVM_INFO\s+verilog_src\/questa_uvm_pkg-/ ||
                /\#\s+UVM_INFO\s+@\s+0:\s+reporter\s+\[RNTST\]\s+Running\s+test/) {
                # Abort (after detected start or UVM package info if used +UVM_NO_RELNOTES)
                # 'vsim' messages:
                # UVM_INFO verilog_src/questa_uvm_pkg-...
                # UVM_INFO @ 0: reporter [RNTST] Running test ...
                $uvm_relnotes_scan = 0;
            }
            if (not $uvm_relnotes_detected) {
                # Start
                $uvm_relnotes_detected = 1;
            }
        }
    }

    # Abort scanning of UVM header messages
    if ($questa_uvm_pkg_scan &&
        # 'vsim' messages:
        # UVM_INFO @ 0: reporter [RNTST] Running test my_test...
        /\#\s+UVM_INFO\s+@\s+0:\s+reporter\s+\[RNTST\]\s+Running\s+test/) {
        $questa_uvm_pkg_scan = 0;
    }

    # Start of simulation
    # 'vsim' messages:
    # "# run -all"
    if (/^#\s+run\s+/) {
        $loading_scan = 0;
        $copyright_scan = 0;
        $run_do_file = 0;
    }

    # Start 'vsim' scanner:
    if ($copyright_scan) {
        if (vsim_option_is_true("show_vsim_start_cmd") &&
            /^\#\s+vsim\s+.*$/) {
            # Show running vsim command message:
            # "# vsim ...."
            print;
        }
        if (vsim_option_is_true("show_vsim_start_time") &&
            /^\#\s+Start\s+time:\s+.*$/) {
            # Show start time message:
            # Start time: ...
            print;
        }
        # Wait start of copyright message: '# // ', then wait its end
        if (/^#\s+\/\/\s+$/) {
            # Hide the Copyright message
            $copyrigth_detected = 1;
        } elsif ($run_do_file) {
            # Hide the Copyright message
            unless (/^#\s+\/\/\s+/) {
                print;
            }
        } elsif (/^(\#\s+\*\*\s+)
                  # Title
                  (Note|Warning)
                  (:\s+)
                  (?:
                      # File name
                      ([A-z0-9._\/-]+)
                      # Line number and round brackets
                      (\()([0-9]+)(\))
                      (:\s+)
                  )?
                  # vlog Num
                  (\([^)]+\))?
                  # Message
                  (.*)$/x) {
            # 'vsim' messages:
            # "** Note: (vsim-or-vopt-Num) Message"
            # "** Warning: FileName(LineNum): (vlog-Num) Message."
            # "** Warning: Message"
            # "** Note: Message"
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
            my $warning_type = $field2 eq "Warning";

            print $field1;
            if ($warning_type) {
                print_color("warning_head_color", "$field2");
            } else {
                print_color("note_head_color", "$field2");
            }
            print $field3;
            if ($warning_type) {
                print_color("warning_fname_color", "$field4");
            } else {
                print_color("note_fname_color", "$field4");
            }
            print $field5;
            if ($warning_type) {
                print_color("warning_line_num_color", "$field6");
            } else {
                print_color("note_line_num_color", "$field6");
            }
            print $field7, $field8, $field9;
            if ($warning_type) {
                print_color("warning_message_color", "$field10");
            } else {
                print_color("note_message_color", "$field10");
            }
            print "\n";
        }
    } elsif (/^#\s+vsim_stacktrace.*written\s+$/) {
        # 'vsim' messages:
        # vsim_stacktrace.vstf written
        print_color("error_head_color", $_);
    } elsif ($loading_scan &&
             /^#\s+(Loading|Compiling)\s+/) {
        # 'vsim' messages:
        # Loading ...
        # Compiling ...
    } elsif ($questa_uvm_pkg_scan &&
             /\#\s+UVM_INFO\s+verilog_src\/questa_uvm_pkg-/) {
        # 'vsim' messages:
        # UVM_INFO verilog_src/questa_uvm_pkg-...
    } elsif ($uvm_relnotes_scan && $uvm_relnotes_detected) {
        # Skip UVM release notes message
        if (/^(\#\s+UVM_WARNING)(.*)$/) {
            # 'vsim' messages:
            # UVM_WARNING @ 0: Message...
            my $field1 = $1 || "";
            my $field2 = $2 || "";
            print_color("warning_head_color", "$field1");
            print_color("warning_message_color", "$field2");
            print "\n";
        }
    } elsif (/^(\#\s+\*\*\s+)
              # Title
              (Error)
              (\s+\([^)]+\))?
              (:\s+)
              (\([^)]+\)\s+)?
              (?:
                  # File name
                  ([A-z0-9._\/-]+)
                  # Line number and round brackets
                  (\()([0-9]+)(\))
                  (:)
              )?
              # vlog Num
              (\s+\([^)]+\))?
              # Message
              (.*)$/x) {
        # 'vsim' messages:
        # "** Error: (vsim-Num) FileName(LineNum): Message."
        # "** Error: FileName(LineNum): (vlog-Num) Message."
        # "** Error (Note): FileName(LineNum): (vsim-Num) Message."
        # "** Error (Note): (vsim-Num) Message"
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
        print_color("error_head_color", "$field2");
        print $field3, $field4, $field5;
        print_color("error_fname_color", "$field6");
        print $field7;
        print_color("error_line_num_color", "$field8");
        print $field9, $field10, $field11;
        print_color("error_message_color", "$field12");
        print "\n";
    } elsif (/^(\#\s+\*\*\s+)
              # Title
              (Fatal:|Error:|Warning:|Note:|Info:)
              # Message
              (.*)$/x) {
        # 'vsim' message:
        # "# ** Error: Message"
        my $field1   = $1 || "";
        my $field2   = $2 || "";
        my $field3   = $3 || "";
        my $warning_type = $field2 eq "Warning:";
        my $note_type = $field2 eq "Note:" || $field2 eq "Info:";

        print $field1;
        if ($note_type) {
            print_color("note_head_color", "$field2");
        } elsif ($warning_type) {
            print_color("warning_head_color", "$field2");
        } else {
            print_color("error_head_color", "$field2");
        }
        if ($note_type) {
            print_color("note_message_color", "$field3");
        } elsif ($warning_type) {
            print_color("warning_message_color", "$field3");
        } else {
            print_color("error_message_color", "$field3");
        }
        print "\n";
    } elsif (/^(\#\s+)
              (Errors:\s+)
              ([0-9]+)
              (,\s+)
              (Warnings:\s+)
              ([0-9]+)
              # Only for MinGW:
              (\s*)
              $/x) {
        # 'vsim' message:
        # "# Errors: Num, Warnings: Num"
        my $field1    = $1 || "";
        my $field2    = $2 || "";
        my $error_num = int($3) || 0;
        my $field4    = $4 || "";
        my $field5    = $5 || "";
        my $warning_num  = int($6) || 0;

        print $field1;
        if ($error_num > 0) {
            print_color("error_head_color", "${field2}$error_num");
        } else {
            print $field2, $error_num;
        }
        print $field4;
        if ($warning_num > 0) {
            print_color("warning_head_color", "${field5}$warning_num");
        } else {
            print $field5, $warning_num;
        }
        print "\n";
    } elsif (/^([#]\s+)?
              (
                  (?:Error\s+loading\s+design)|
                  (?:Optimization\s+failed)|
                  (?:No\s+such\s+file\s+or\s+directory)
              )
              (.*)
              $/x) {
        my $field1    = $1 || "";
        my $field2    = $2 || "";
        my $field3    = $3 || "";
        print $field1;
        print_color("error_head_color", "$field2");
        print $field3, "\n";
    } elsif (/^(\#\s+)
              # Title
              # (Fatal)
              (Fatal\s+error|Fatal|Stopped)
              # Message
              (.*)$/x) {
        # 'vsim' message:
        # "# Fatal error Message"
        # "# Sopped at Message"
        my $field1   = $1 || "";
        my $field2   = $2 || "";
        my $field3   = $3 || "";

        print $field1;
        print_color("error_head_color", "$field2");
        print_color("error_message_color", "$field3");
        print "\n";
    } else {
        if (@vsim_hi_patterns &&
            vsim_option_is_true("vsim_hi_patterns_en")) {
            my $str = $_;
            my $match = 0;
            my @patterns = @vsim_hi_patterns;
            while (my ($mask, $color) = splice(@patterns, 0, 2)) {
                if ($str =~ /$mask/) {
                    chomp($str); # remove newline to prevent overlay color
                    eval {
                        print(color($color), $str, color("reset"));
                    } or do print $str, "(Waring: $0: Wrong 'vsim_hi_patterns' color options: <$color>)";
                    print "\n";
                    $match = 1;
                }
            }
            if (not $match) {
                print;          # Nothing found. Print current line without changes.
            }
        } else {
            print;              # Nothing found. Print current line without changes.
        }
    }                           # else
}                               # vsim_scan

sub error_summary_parser
{
    if (/^(Errors:\s+)
         ([0-9]+)
         (,\s+)
         (Warnings:\s+)
         ([0-9]+)
         # Only for MinGW:
         (\s*)
         $/x) {
        # 'vlog' message:
        # "Errors: Num, Warnings: Num"
        my $field1    = $1 || "";
        my $error_num = int($2) || 0;
        my $field3    = $3 || "";
        my $field4    = $4 || "";
        my $warning_num  = int($5) || 0;
        if ($error_num > 0) {
            print_color("error_head_color", "${field1}$error_num");
        } else {
            print $field1, $error_num;
        }
        print $field3;
        if ($warning_num > 0) {
            print_color("warning_head_color", "${field4}$warning_num");
        } else {
            print $field4, $warning_num;
        }
        print "\n";
    }
}                               # error_summary_parser

sub print_color
{
    print($colors{$_[0]}, $_[1], color("reset"));
}

sub trim
{
    $_[0] =~ s/^\s+|\s+$//g;
}
