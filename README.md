# Color QuestaSim (colorquestasim)

A wrapper to colorize the output from Mentor Graphics QuestaSim messages.

# Install

- Copy [colorquestasim.pl](colorquestasim.pl) in a directory of your choice.
- Create symbol links pointing to `colorquestasim.pl`. This link must be named as the name of
  the QuestaSim command.  The directory where these links are created must be placed in `$PATH`
  **before** the directory where the QuestaSim commands lives.

Example:
```bash
cp colorquestasim.pl ~/bin/
cd ~/bin
ln -s colorquestasim.pl vlog
ln -s colorquestasim.pl vopt
ln -s colorquestasim.pl vsim
export PATH="$HOME/bin:$PATH"
```

# Configuration

The default settings can be overridden with `~/.colorquestasim` or
`~/.colorquestasim_<os_type>`.

See the comments in the sample [colorquestasim.txt](colorquestasim.txt) for more information.

![Screenshot](image/Screenshot.png "Screenshot")

# Known Issues

## Startup problem on Windows OS (MinGW)

`colorquestasim` does not work on Windows (the 'find_path' function of this script is too slow),
to fix this, you need to write the path to all QuestaSim commands in `~/.colorquestasim`,
for example:

>vlog: /your_path2questasim_install_dir/win64/vlog

## Links to vopt, vsim commands do not work on Windows OS (MinGW)

`colorquestasim` do not supports 'vopt', 'vsim' QuestaSim commands for Windows OS.

If you create links to 'vopt', 'vsim' QuestaSim commands to `colorquestasim.pl`, then executing
these links will result in error:

    vopt -quiet example_err_vsim -o prj_optrj_opt
    ** Error (suppressible): (vlog-1902) Option "-o" is either unknown, requires an argument, or was given with a bad argument.
    Use the -help option for complete vlog usage.

# Reference
[colorgcc](https://github.com/colorgcc/colorgcc)
