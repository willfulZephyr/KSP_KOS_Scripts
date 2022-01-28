
function main {
    if NOT HASTARGET {
        print "No target selected.".
        print "Exiting program.".
        RETURN.
    }

    // Make sure both target and control point are docking ports
    if TARGET:IsType("DockingPort") {
        if SHIP:CONTROLPART:IsType("DockingPort") {
            print "Beginning docking alignment ...".
        } else {
            print "Control is not a docking port.".
            print "Exiting program.".
            RETURN.
        }
    } else {
        print "Target is not a docking port.".
        print "Exiting program.".
        RETURN.
    }

    // Get direction of the docking port
    local targetDir is TARGET:PORTFACING.
    lock targetDir to TARGET:PORTFACING.
    local headingDir is -1 * targetDir:VECTOR.
    lock headingDir to -1 * targetDir:VECTOR.

    SAS OFF.
    lock steering to LOOKDIRUP(headingDir, targetDir:UPVECTOR).

    local angleErr is 100.
    local rollErr is 100.
    wait 0.25.
    lock angleErr to STEERINGMANAGER:ANGLEERROR.
    lock rollErr to STEERINGMANAGER:ROLLERROR.
    wait 0.01.
    local passCounter is 0.
    UNTIL abs(angleErr) < 0.5 and abs(rollErr) < 1 and passCounter > 5 {
        clearscreen.
        print "Beginning docking alignment ...".
        PRINT(" Facing angle - " + STEERINGMANAGER:ANGLEERROR).
        PRINT(" Roll angle - " + STEERINGMANAGER:ROLLERROR).
        FROM {local i is 1.} UNTIL i > passCounter STEP { SET i to i + 1. } DO {
            PRINT(" .").
        }
        PRINT(" ").
        if abs(angleErr) < 0.5 and abs(rollErr) < 1 {
            set passCounter to passCounter + 1.
        }
        wait 0.01.
    }
    clearscreen.
    PRINT("Alignment complete.").

    LOCK cpos TO SHIP:CONTROLPART:POSITION.
    LOCK tpos TO TARGET:POSITION.
    LOCK tmov TO TARGET:SHIP:VELOCITY:ORBIT.
    LOCK move TO SHIP:VELOCITY:ORBIT.
    LOCK rel TO tmov - move.
    LOCK pointer TO tpos - cpos.
    lock xdis to pointer:MAG * cos(vang(pointer, ship:Facing:forevector)).
    lock ydis to pointer:MAG * cos(vang(pointer, ship:Facing:topvector)).
    lock zdis to pointer:MAG * cos(vang(pointer, ship:Facing:starvector)).
    lock xrel to rel:MAG * cos(vang(rel, ship:Facing:forevector)).
    lock yrel to rel:MAG * cos(vang(rel, ship:Facing:topvector)).
    lock zrel to rel:MAG * cos(vang(rel, ship:Facing:starvector)).

    print "Distance" AT (12, 1).
    print "Velocity" AT (25, 1).
    print "Fore/Aft: " AT (2, 2).
    print "Up/Down: " AT (2, 3).
    print "Right/Left: " AT (2, 4).
    UNTIL SHIP:CONTROLPART:STATE <> "Ready" OR NOT HASTARGET {
        print PadAndRound(xdis, 1) AT (14, 2).
        print PadAndRound(ydis, 1) AT (14, 3).
        print PadAndRound(zdis, 1) AT (14, 4).
        print PadAndRound(xrel, 2) AT (27, 2).
        print PadAndRound(yrel, 2) AT (27, 3).
        print PadAndRound(zrel, 2) AT (27, 4).
        HighlightRow(xdis, xrel, 2).
        HighlightRow(ydis, yrel, 3).
        HighlightRow(zdis, zrel, 4).
        WAIT 0.01.
    }

    clearscreen.
    print "Docked!".
    unlock steering.
    SAS ON.

}

function PadAndRound {
    parameter value.
    parameter precision.
    local formatted is ROUND(value, precision).
    if value < -100 {
        return formatted.
    }
    if value < -10 {
        return " " + formatted.
    }
    if value < 0 {
        return "  " + formatted.
    }
    if value < 10 {
        return "   " + formatted.
    }
    if value < 100 {
        return "  " + formatted.
    }
    return " " + formatted.
}
function HighlightRow {
    parameter distance.
    parameter speed.
    parameter row.
    if ABS(distance) < 0.1 AND ABS(speed) < 0.05 {
        // DONE!
        print ">" AT (0, row).
        print "<" AT (35, row).
        return.
    }
    if (distance < 0 AND speed > 0) OR (distance > 0 AND speed < 0) {
        // Good!
        print "-" AT (0, row).
        print "-" AT (35, row).
        return.
    } 
    if (distance < 0 AND speed < 0) OR (distance > 0 AND speed > 0) {
        // BAD!
        print "@" AT (0, row).
        print "@" AT (35, row).
        return.
    } 
    // Netral
    print " " AT (0, row).
    print " " AT (35, row).
}

main().