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

## Compiling those files
Run compilescripts.

## Updating the compiled scripts on a vessel
Runpath("0:reloadlocalfiles").

This will also update the bootfile.
