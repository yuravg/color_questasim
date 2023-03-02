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

[Issues for QuestaSim version 10.7c on Window OS (MinGW)](issues_questasim10c7_mingw.md)

# Reference
[colorgcc](https://github.com/colorgcc/colorgcc)
