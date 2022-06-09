@LAZYGLOBAL OFF.

function isReadyToDock {
    if NOT HASTARGET {
        print "No target selected.".
        print "Exiting program.".
        RETURN FALSE.
    }

    // Make sure both target and control point are docking ports
    if TARGET:IsType("DockingPort") {
        if SHIP:CONTROLPART:IsType("DockingPort") {
            RETURN TRUE.
        } else {
            print "Control is not a docking port.".
            RETURN FALSE.
        }
    } else {
        print "Target is not a docking port.".
        RETURN FALSE.
    }

}

function isSteeringDone {
    local lock angleErr to STEERINGMANAGER:ANGLEERROR.
    local lock rollErr to STEERINGMANAGER:ROLLERROR.
    wait 0.25.
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
    return true.
}

function getTargetExclusionZone {
    return ABS(TARGET:SHIP:BOUNDS:EXTENDS:MAG) * 1.25.
}

function getTotalRCSThrust {
    local rcsThrusters is 0.
    LIST RCS in rcsThrusters.
    local totalRcsThrust is 0.

    for thruster IN rcsThrusters {
        if thruster:enabled {
            set totalRcsThrust to totalRcsThrust + thruster:AVAILABLETHRUST.
        }
    }

    return totalRcsThrust.
}

function setRCSThrust {
    parameter limit is 100.
    local rcsThrusters is 0.
    LIST RCS in rcsThrusters.
    FOR thruster IN rcsThrusters {
        if thruster:enabled {
            // Only update active thrusters
            set thruster:thrustlimit to limit.
        }
    }

}



