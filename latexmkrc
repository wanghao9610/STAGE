# Read by latexmk when it is started from the repository root, as
# `bash execs/run.sh`, lint.sh, and the LaTeX Workshop external build are.
# An engine run without -synctex deletes an existing .synctex.gz, so every
# build writes one and editor <-> PDF jumps survive command-line builds.
set_tex_cmds('-synctex=1 %O %S');
