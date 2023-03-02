## Issues for QuestaSim version 10.7c on Window OS (MinGW)

(version 2021.01 does not have these issues)

### Startup problem on Windows OS

`colorquestasim` does not work on Windows (the 'find_path' function of this script is too slow),
to fix this, you need to write the path to all QuestaSim commands in `~/.colorquestasim`,
for example:

>vlog: /your_path2questasim_install_dir/win64/vlog

### Links to vopt, vsim commands do not work on Windows OS

`colorquestasim` do not supports 'vopt', 'vsim' QuestaSim commands for Windows OS.

If you create links to 'vopt', 'vsim' QuestaSim commands to `colorquestasim.pl`, then executing
these links will result in error:

    vopt -quiet example_err_vsim -o prj_optrj_opt
    ** Error (suppressible): (vlog-1902) Option "-o" is either unknown, requires an argument, or was given with a bad argument.
    Use the -help option for complete vlog usage.
