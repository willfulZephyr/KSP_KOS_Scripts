SWITCH TO 1.
LIST FILES IN currentFiles.
local idx is currentFiles:ITERATOR.

UNTIL NOT idx:NEXT {
    if idx:VALUE:IsFile {
        DELETEPATH(idx:VALUE:NAME).
        PRINT "DELETING " + idx:VALUE:NAME + " - FILE".
    }
}
COPYPATH("0:/boot/bootfile.ks", "1:/boot/bootfile.ks").
// Reboot the core.
reboot.
