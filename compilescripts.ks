@LAZYGLOBAL OFF.

local compiledDir is "0:/compiled/".
local programsToCompile is LIST(
    "align", 
    "circle",
    "common",
    "engine_lex",
    "engine",
    "landerscripts",
    "landing",
    "launch",
    "node",
    "reentry"
).

function main {
    DELETEPATH(compiledDir).
    CREATEDIR(compiledDir).
    local idx is programsToCompile:ITERATOR.
    until NOT idx:NEXT {
        local source is "0:" + idx:VALUE + ".ks".
        local destination is compiledDir + idx:VALUE + ".ksm".
        COMPILE source to destination.
        wait 0.01.
    }
}

main().