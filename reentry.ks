@LAZYGLOBAL OFF.

run once common.

function plannedVector {
    return ADDONS:TR:PLANNEDVECTOR.
}

function offsetPitch {
    // Get the angle-from horizon for planned vector
    local plannedFore is vectorexclude(ship:FACING:STARVECTOR, ADDONS:TR:PLANNEDVECTOR).
    local correctedFore is vectorexclude(ship:FACING:STARVECTOR, ADDONS:TR:CORRECTEDVECTOR).
    local plannedPitch is vectorangle(plannedFore, bestPrograde()).
    local correctedPitch is vectorangle(correctedFore, bestPrograde()).
    local pitch is correctedPitch - plannedPitch.
    // Apply a 1-degree offset, since I like to come in short
    set pitch to pitch - 1.
    if pitch < 0 {
        if pitch < -10 {
            return -30.
        }
        return 3 * pitch.
    }
    return MIN(pitch, 10).
}

function bestPrograde {
    if NAVMODE = "SURFACE" {
        return ship:srfprograde:VECTOR.
    } else if NAVMODE = "ORBIT" {
        return ship:prograde:VECTOR.
    }
}

function offsetYaw {
    // Get the angle-from prograde for vectors
    local plannedYaw is vectorexclude(ship:FACING:TOPVECTOR, ADDONS:TR:PLANNEDVECTOR).
    local correctedYaw is vectorexclude(ship:FACING:TOPVECTOR, ADDONS:TR:CORRECTEDVECTOR).
    local letsRoll is vectorangle(correctedYaw, plannedYaw).
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
    local pitchOffset is 0.
    local rollOffset is 0.
    local plannedV is 0.
    lock plannedV to plannedVector().
    lock pitchOffset to offsetPitch().
    lock rollOffset to offsetYaw().
    local pitchVector is 0.
    lock steering to ANGLEAXIS(offsetPitch(), SHIP:FACING:STARVECTOR) * plannedVector().
    // to ANGLEAXIS(rollOffset, SHIP:FACING:FOREVECTOR) * pitchVector.
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