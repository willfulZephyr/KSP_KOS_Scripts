@LAZYGLOBAL OFF.

function main {
    // Parsed values are:
    //  n - Normal: point 'upward' for surface-attached panels (default)
    //  i - Inverted: point 'downward' for surface-attached panels (default)
    //  d - Dorsal: point parallel to the sun, with the dorsal/ventral line 'up'
    //  l - Lateral: point parallel to the sun, with the dorsal/ventral line pointing at the sun
    //  f - Flower: point towards the sun, like a flower, for panels all pointing to the sun
    parameter alignType.

    // Get vector to sun, up, and normal to them
    local sunvctr is SUN:POSITION.
    local northvctr is V(0, 1, 0).
    local downvctr is V(0, -1, 0).
    local perpvctr is VECTORCROSSPRODUCT(sunvctr, northvctr).

    // default, "n" orientation
    local upDir is SHIP:PROGRADE:VECTOR.
    local lookDir is northvctr.

    if alignType = "l" {
        set lookDir to perpvctr.
        set upDir to sunvctr.
    }
    if alignType = "d" {
        set lookDir to perpvctr.
        set upDir to northvctr.
    }
    if alignType = "f" {
        set lookDir to sunvctr.
        set upDir to northvctr.
    }
    if alignType = "i" {
        set lookDir to downvctr.
    }
    if alignType = "b" {
        set lookDir to -sunvctr.
        set upDir to northvctr.
    }
    if alignType = "t" {
        set lookDir to perpvctr.
        set upDir to sunvctr.
    }

    sas off.
    lock steering to LOOKDIRUP(lookDir, upDir).
    //lock steering to HEADING(0, pitchVal) + R(0, yawVal, rollVal).
    local angleErr is 100.
    local rollErr is 100.
    wait 0.25.
    lock angleErr to STEERINGMANAGER:ANGLEERROR.
    lock rollErr to STEERINGMANAGER:ROLLERROR.
    wait 0.01.
    local passCounter is 0.
    UNTIL abs(angleErr) < 0.5 and abs(rollErr) < 1 and passCounter > 5 {
        clearscreen.
        PRINT("Aligning to '" + alignType + "' ...").
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
    PRINT("Alignment complete.").

    unlock steering.
    sas on.
}

parameter alignType is "n".
main(alignType).