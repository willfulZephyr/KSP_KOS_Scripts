@LAZYGLOBAL OFF.

function getHeight {
    return ship:altitude - ship:geoposition:terrainheight.
}

function getCurrentTWR {
    local engList is LIST().
    LIST ENGINES IN engList.
    local totalThrust is 0.
    FOR eng IN engList {
        if eng:MAXTHRUST > 0 {
            // sum active engines
            set totalThrust to totalThrust + eng:AVAILABLETHRUST.
        }
    }
    local g is body:mu / (body:radius)^2.
    return (totalThrust / (ship:mass * g)).
}

function getMaxTWR {
    local engList is LIST().
    LIST ENGINES IN engList.
    local totalThrust is 0.
    FOR eng IN engList {
        if eng:MAXTHRUST > 0 {
            // sum active engines
            set totalThrust to totalThrust + eng:MAXTHRUST.
        }
    }
    local g is body:mu / (body:radius)^2.
    return (totalThrust / (ship:mass * g)).
}

function getInput {
    PARAMETER preface IS "input: ", line IS -1.
    LOCAL str IS "".
    if line > -1 {
        PRINT (preface + str):PADRIGHT(TERMINAL:WIDTH) AT(0,line).
    } else {
        PRINT (preface + str):PADRIGHT(TERMINAL:WIDTH).
    }
    UNTIL FALSE {
        IF TERMINAL:INPUT:HASCHAR {
            LOCAL inChar IS TERMINAL:INPUT:GETCHAR().
            IF inChar = TERMINAL:INPUT:ENTER {
                RETURN str.
            } ELSE {
                IF str:LENGTH + preface:LENGTH >= TERMINAL:WIDTH {
                    PRINT CHAR(7).
                    RETURN str.
                } ELSE {
                    SET str TO str + inChar.
                }
            }
            if line > -1 {
                PRINT (preface + str):PADRIGHT(TERMINAL:WIDTH) AT(0,line).
            } else {
                PRINT (preface + str):PADRIGHT(TERMINAL:WIDTH).
            }
        }
        WAIT 0.
    }
}

// Do not run this while under acceleration - apoapsis and periapsis are still changing.
function createCircularMan {
    // Expecting to know if this should circle at apoapsis or periapsis
    parameter apOrPer.

    // Calculate the target Orbital Velocity
    local targetVelocity is 0.
    local targetAltitude is 0.
    local targetPeriod is 0.

    if apOrPer = "apoapsis" {
        set targetAltitude to ship:orbit:apoapsis.
    }
    if apOrPer = "periapsis" {
        set targetAltitude to ship:orbit:periapsis.
    }

    print "Aiming for " + targetAltitude + "m".

    // Calculate target orbital period for a circular orbit of targetAltitude
    set targetPeriod to SQRT((body:radius + targetAltitude)^3 / body:mu) * 2 * Constant:Pi.

    print "with an orbital period of " + targetPeriod + " seconds.".

    // Calculate target orbital velocity for circular orbit at targetAltitude
    set targetVelocity to (2 * Constant:Pi * (body:radius + targetAltitude)) / targetPeriod.
    print "This requires a velocity of " + targetVelocity.

    // Get expected speed at target
    local startingVelocity is 0.
    if apOrPer = "apoapsis" {
        set startingVelocity to VELOCITYAT(ship, TIME + ship:orbit:ETA:apoapsis).
    }
    if apOrPer = "periapsis" {
        set startingVelocity to VELOCITYAT(ship, TIME + ship:orbit:ETA:periapsis).
    }

    // Calculate the deltaV required to set orbit.
    local gradeDeltaV is targetVelocity - startingVelocity:orbit:mag.

    print "This requires " + gradeDeltaV + " of deltaV.".

    // Create the manuever node - I wait to here so the ETA is more accurate
    local circNode is 0.
    if apOrPer = "apoapsis" {
        set circNode to Node(TIME + ship:orbit:ETA:apoapsis, 0, 0, gradeDeltaV).
        print "Apoapsis in " + ship:orbit:ETA:apoapsis.
    }
    if apOrPer = "periapsis" {
        set circNode to Node(TIME + ship:orbit:ETA:periapsis, 0, 0, gradeDeltaV).
        print "Periapsis in " + ship:orbit:ETA:apoapsis.
    }

    add(circNode).
}

// Executes the next manuever node in the orbit
function doNode {
    if HASNODE {
        CLEARSCREEN.
        sas off.
        local startReduceTime to 1.5.
        local nd is NEXTNODE.
        local startTime is calculateStartTime(nd, startReduceTime).
        local startVector is nd:BURNVECTOR.
        lockSteering(nd).
        startBurn(startTime).
        if reduceThrottle(nd, startReduceTime) < 0 {
            // Ran out of fuel
            lock throttle to 0.
            unlock steering.
            unlock throttle.
        } else {
            endBurn(nd, startVector).
        }
        sas on.
    } else {
        print " ".
        print "No nodes in flight plan.".
        print " ".
    }
}

// Use node and offset to plan start time
function calculateStartTime {
    parameter nd.
    parameter startReduceTime.
    setLimit(100).
    local percent is 100.
    local calculatedBurnTime is burnTime(nd:BURNVECTOR:MAG).
    until calculatedBurnTime > 8 {
        // This is too short, lower engine power
        set percent to percent - scaledPercent(percent).
        setLimit(percent).
        set calculatedBurnTime to burnTime(nd:BURNVECTOR:MAG).
        if percent = 0.1 {
            print "At minimum thrust. Reducing cutoff".
            set startReduceTime to 0.5.
            break.
        }
    }
    print "Estimated Burn Time: " + calculatedBurnTime.
    local halfDeltaV is nd:BURNVECTOR:MAG / 2.
    local meanTimeToNode is burnTime(halfDeltaV).
    return TIME:SECONDS + nd:ETA - meanTimeToNode - startReduceTime/2.
    //return TIME:SECONDS + nd:ETA - calculatedBurnTime/2 - startReduceTime/2.
}

function setLimit {
    parameter limit.
    local engList is LIST().
    LIST ENGINES IN engList.
    FOR eng IN engList {
        if eng:IGNITION {
            // Only update active engines
            set eng:thrustlimit to limit.
        }
    }
}

function scaledPercent {
    parameter oldPercent.
    if oldPercent > 50 {
        return 10.
    } else if oldPercent > 10 {
        return 5.
    } else if oldPercent > 1 {
        return 1.
    } else {
        return 0.1.
    }
}

// Calculate how long this burn will take (updates)
function burnTime {
    //parameter nd.
    //local deltaV to nd:BURNVECTOR:MAG.
    parameter deltaV.
    // Must have an ISP for this calculation
    if (vesselISP() < 0) {
        print " ".
        print "NO ACTIVE ENGINES. Please activate at least one.".
        wait until (vesselISP() > 0).
    }
    // Get final mass using vis-visa, which needs the ISP
    local finalMass to ship:MASS / (CONSTANT:E^(deltaV / ( vesselISP() * CONSTANT:g0 ))).

    // change in acceleration is NOT linear - so don't average, my friend, it'll be off on long burns
    return (deltaV * (ship:MASS - finalMass)) / (ship:AVAILABLETHRUST * LN(ship:MASS / finalMass)).
}

// Calculate the effective ISP for the vessel
function vesselISP {
    local engineList is 0.
    LIST ENGINES in engineList.
    local sumThrust to 0.
    local sumFractISP to 0.
    for engine in engineList {
        IF engine:IGNITION {
            set sumThrust to sumThrust + engine:AVAILABLETHRUST.
            set sumFractISP to sumFractISP + (engine:AVAILABLETHRUST / engine:VISP).
        }
    }
    if (sumFractISP > 0) {
        // This removes the AVAILABLETHRUST, leaving the ISP built up proportionately
        return sumThrust / sumFractISP.
    } else {
        return -1.
    }
}

// Lock the steering to the node
function lockSteering {
    parameter nd.
    lock steering to nd:BURNVECTOR.
    PRINT " ".
    print "Locking to the burn vector.".
    local angleErr is 100.
    local rollErr is 100.
    wait 0.25.
    lock angleErr to STEERINGMANAGER:ANGLEERROR.
    lock rollErr to STEERINGMANAGER:ROLLERROR.
    wait 0.01.
    UNTIL abs(angleErr) < 0.5 and abs(rollErr) < 1 {
        wait 0.01.
    }
    PRINT("Lock complete.").
}

// Start the burn
function startBurn {
    parameter startTime.
    if TIME:SECONDS < (startTime - 40) {
        set warp to 2.
    }
    wait until TIME:SECONDS > (startTime - 20).
    if (warp > 0) {
        set warp to 0.
    }
    wait until TIME:SECONDS > (startTime - 3).
    print " ".
    print "About to start burn.".
    wait until TIME:SECONDS >= startTime.
    print "Throttle to full.".
    lock throttle to 1.
}

// Reduce the throttle over the startReduceTime
function reduceThrottle {
    parameter nd.
    parameter startReduceTime.

    until burnTime(nd:BURNVECTOR:MAG) < startReduceTime {
        if stage:deltaV:current < 0.1 {
            local curStageNumber is ship:stagenum.
            if ship:stagedeltav(curStageNumber - 1):current > 0 {
                // The next stage has DELTAV
                STAGE.
            } else {
                print "Out of fuel. Exiting.".
                return -1.
            }
        }
    }    
    print " ".
    print "Reducing throttle".
    
    // Reduce time is spread out over more as we reduce thrust
    local reduceTime to startReduceTime * 2 / 0.9.
    local startTime to TIME:SECONDS.
    local stopTime to TIME:SECONDS + reduceTime.
    local scale to 0.1^(1/reduceTime).

    lock throttle to scale^(TIME:SECONDS - startTime).
    wait until TIME:SECONDS > stopTime.

    // set throttle as low as we can go while waiting to finish.
    lock throttle to 0.1.
    return 1.
}

// Finish up the burn
function endBurn {
    parameter nd.
    parameter startVector.

    wait until maneuverComplete(nd, startVector).

    print " ".
    print "Burn complete.".
    print " ".

    lock throttle to 0.
    // Have to unlock steering before you can remove the node (steering is locked to the node)
    unlock steering.
    unlock throttle.
    REMOVE nd.

    wait 2.
}

// Are we done? Look for divergine off the expecting vector
function maneuverComplete {
    parameter nd.
    parameter startVector.
    return VANG(startVector, nd:BURNVECTOR) > 5.
}

// Clean Staging
function doStage {
    STAGE.
    wait 0.1.
}