@LAZYGLOBAL OFF.

run once common.

function plannedVector {
    return ADDONS:TR:PLANNEDVECTOR.
}

function offsetPitch {
    // Takes the normal vector as a parameter (don't want to keep calculating it)
    parameter normal.
    parameter upVec.

    // Get the angle-from horizon for planned vector
    local plannedFore is vectorexclude(normal, ADDONS:TR:PLANNEDVECTOR).
    local correctedFore is vectorexclude(normal, ADDONS:TR:CORRECTEDVECTOR).
    local plannedPitch is vectorangle(plannedFore, upVec).
    local correctedPitch is vectorangle(correctedFore, upVec).

    // Set pitch for reentry
    local pitch is correctedPitch - plannedPitch.
    // "Add" one to pitch, as I like to pull a little short
    set pitch to pitch + 1.

    if pitch > 0 {
        if pitch > 10 {
            return 30.
        }
        return 3 * pitch.
    }
    return MAX(pitch, -10).
}

function bestPrograde {
    if NAVMODE = "SURFACE" {
        return ship:srfprograde:VECTOR.
    } else if NAVMODE = "ORBIT" {
        return ship:prograde:VECTOR.
    }
}

function offsetYaw {
    // Takes the normal vector as a parameter (don't want to keep calculating it)
    parameter normal.
    parameter upVec.

    // Get the angle-from prograde for vectors
    local plannedFore is vectorexclude(upVec, ADDONS:TR:PLANNEDVECTOR).
    local correctedFore is vectorexclude(upVec, ADDONS:TR:CORRECTEDVECTOR).

    local plannedYaw is vectorangle(plannedFore, normal).
    local correctedYaw is vectorangle(correctedFore, normal).

    local letsRoll is plannedYaw - correctedYaw.
    if ABS(letsRoll * 5) <= 30 {
        return letsRoll * 5.
    }
    return 30 * (letsRoll / ABS(letsRoll)).
}

function main {
    parameter releaseAltitude.
    if releaseAltitude < 1000 {
        set releaseAltitude to releaseAltitude * 1000.
    }
    wait until ship:altitude < (body:ATM:HEIGHT + 1000).
    print "Reentry begun. Assuming control.".
    sas off.
    local lookAt is 0.
    local lookUp is 0.
    local normal is 0.
    local upVec is V(0, 0, 0).
    
    lock upVec to ((-1)*SHIP:BODY:POSITION).
    lock normal to vectorcrossproduct(ship:velocity:surface, upVec).
    lock lookAt to ANGLEAXIS(offsetPitch(normal, upVec), normal) * plannedVector().
    lock lookUp to ANGLEAXIS(offsetYaw(normal, upVec), SHIP:FACING:FOREVECTOR) * ((-1)*SHIP:BODY:POSITION).
    lock steering to LOOKDIRUP(lookAt, lookUp).
    //lock steering to LOOKDIRUP(lookAt, upVec).
    local voice is  GETVOICE(0).
    local beep is NOTE("C4", 0.1, 0.15).
    local rest is NOTE("R", 0.1).
    wait until ship:altitude < (releaseAltitude + 5000).
    voice:play(LIST(beep, rest, beep, rest, beep)).
    print (releaseAltitude + 5000) + "m, preparing to release control.".
    wait until ship:altitude < (releaseAltitude + 2000).
    voice:play(LIST(beep, rest, beep)).
    print (releaseAltitude + 2000) + "m, get ready to assume control.".
    wait until ship:altitude < releaseAltitude.
    voice:play(beep).
    print releaseAltitude + "m, returning control to pilot.".
    unlock steering.
    sas on.
}

parameter releaseAltitude.
main(releaseAltitude).