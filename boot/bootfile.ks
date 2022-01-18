// put at the top of most boot files:
print "Waiting for ship to unpack.".
wait until ship:unpacked.
print "Ship is now unpacked.".
if not EXISTS("common.ksm") {
    print "Copying base files.".
    copypath("0:/compiled/common.ksm", "common.ksm").
    copypath("0:/compiled/engine_lex.ksm", "engine_lex.ksm").
    copypath("0:/compiled/node.ksm", "node.ksm").
    copypath("0:/compiled/circle.ksm", "circle.ksm").
    copypath("0:/compiled/engine.ksm", "engine.ksm").
    copypath("0:/compiled/align.ksm", "align.ksm").
}
if ship:status = "PRELAUNCH" {
    print "Prelaunch. Open KOS window and fire up the launch script.".
    core:doevent("Open Terminal").
    runpath("0:launch").
} else {
    if HASNODE {
        print "Upcoming manuever. Open KOS window.".
        core:doevent("Open Terminal").
    }
}