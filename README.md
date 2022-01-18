# KSP_KOS_Scripts
KOS Scripts for playing Kerbal Space Program

## Bootfile
The bootfile is expecting a directory called "compiled", where it will copy the compiled forms of 
* common
* engine_lex
* engine
* node
* circle
* align

If it is missing, it will just skip that. If prelaunch, it will open the terminal and start the launchscript from the archive (runpath("0:launch").). If there is a manuever node scheduled, it will open the terminal.

## Compiling those files
Run compilescripts.

It will clear and (re-)create the compiled directory.

## Updating the compiled scripts on a vessel
Runpath("0:reloadlocalfiles").

This will delete your local files, update the bootfile, and reboot - which should reload the compiled files.
