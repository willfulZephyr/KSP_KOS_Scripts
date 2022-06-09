@LAZYGLOBAL OFF.

run once common.

function main {
    clearscreen.
    print "Prelaunch...".
    print "".
    local targetInclination is getInput("Enter target inclination (degrees - 0): ", 2):TONUMBER(0).
    print "Target is " + targetInclination + " degrees." at (0, 3).
    print "" at (0, 4).

    local targetAltitude is getInput("Enter target altitude (km - 80): ", 5):TONUMBER(80).
    set targetAltitude to targetAltitude * 1000.
    print "Target is " + targetAltitude + " meters."  at (0, 6).
    print "" at (0, 7).

    if body:name = "Kerbin" {
        KSCLaunch(targetInclination, targetAltitude).
    }
    if body:name = "Mun" {
        MunLaunch(targetInclination, targetAltitude).
    }
    if body:name = "Minmus" {
        MinmusLaunch(targetInclination, targetAltitude).
    }
}

function KSCLaunch {

    parameter targetInclination.
    parameter targetAltitude.

    print "Launching from KSC" at (0, 8).
    print " " at (0, 9).

    local pitchStartSpeed is getInput("Enter speed to start pitchover (m/s - 50): ", 10):TONUMBER(50).
    print "Target is " + pitchStartSpeed + " meters/second." at (0, 11).
    print "" at (0, 12).

    local rollAttitude is getInput("Enter roll attitude (default, n, or i): ", 13).
    print "" at (0, 14).

    print "Readying..." at (0, 15).
    wait 1.
    
    // Mike Abens ascent profile (uses MATH)
    local mathPitchKerbin IS {
        local pitchStart is 500.
        local halfPitchedAlt is 10000.
        if ship:altitude < pitchStart {
            return 90.
        } else if ship:altitude < 40000 {
            return 90 * (halfPitchedAlt / (ship:altitude - pitchStart + halfPitchedAlt)).
        } else {
            // return prograde
            if NAVMODE = "SURFACE" {
                return 90 - VANG(ship:srfprograde:VECTOR, ship:UP:VECTOR).
            } else if NAVMODE = "ORBIT" {
                return 90 - VANG(ship:prograde:VECTOR, ship:UP:VECTOR).
            }
        }
    }.

    local mathThrottleKerbin IS {
        local twrUppitude is 3.
        if stage:deltaV:current < 0.1 {
            STAGE.
            STEERINGMANAGER:RESETPIDS().
        }
        if (ship:altitude < 10000) {
            // Ramp up from 1.33 to MAX
            local twrFloor is 1.33.
            return twrFloor + ((twrUppitude - twrFloor) * ship:altitude / 10000).
        } else if (ship:altitude < 19000) {
            // punch it through the lower atmosphere
            return twrUppitude.
        } else if (ship:altitude < 20500) {
            // Flying High - ramp down to 1.25
            local twrFloor is 1.25.
            return twrFloor + ((twrUppitude - twrFloor) * (20500 - ship:altitude) / 2000).
        } else if (ship:altitude < 40000) {
            if ship:orbit:ETA:apoapsis < 50 {
                return 1.4.
            } else if ship:orbit:ETA:apoapsis < 60 {
                return 1.2.
            } else if ship:orbit:ETA:apoapsis < 75 {
                return 1.10.
            } else {
                return 1.0.
            }
        } else if (ship:altitude < 55000) {
            if ship:orbit:ETA:apoapsis < 50 {
                return 1.0.
            } else if ship:orbit:ETA:apoapsis < 60 {
                return 0.9.
            } else if ship:orbit:ETA:apoapsis < 75 {
                return 0.75.
            } else {
                return 0.6.
            }
        } else if (ship:altitude < 70000) {
            if ship:orbit:ETA:apoapsis < 50 {
                return 0.9.
            } else if ship:orbit:ETA:apoapsis < 60 {
                return 0.75.
            } else if ship:orbit:ETA:apoapsis < 75 {
                return 0.6.
            } else {
                return 0.5.
            }
        } else {
            return 0.5.
        }
    }.

    local throwaway is getInput("Hit ENTER to launch at " + targetInclination + " degrees to " + targetAltitude + " meters.", 16).
    clearscreen.

    local launchStage is ship:stageNum - 1.
    local stageCount is getEngineCount(launchStage).

    wait 1.
    print "3...".
    wait 1.
    print "2...".
    wait 1.
    print "1...".
    wait 1.

    // KSC starts with staging.
    doStage().
    print "Ignition...".
    wait 0.25.

    // Did all the engines start?
    if wasThereAnEngineFailure(stageCount) {
        print "Shutting everything down and exiting.".
        for eng in engList {
            eng:SHUTDOWN.
        }
        RETURN.
    }

    doLaunch(targetInclination, targetAltitude, pitchStartSpeed, mathPitchKerbin, mathThrottleKerbin, rollAttitude).
}

function wasThereAnEngineFailure {
    parameter expectedEngineCount.

    local engList is LIST().
    LIST ENGINES IN engList.
    local launchCount is 0.
    // Lets check
    for eng in engList {
        if eng:STAGE = ship:stageNum {
            if eng:IGNITION = false OR eng:POSSIBLETHRUST = 0 {
                // Engine failure, shut everything down.
                print "ENGINE FAILURE!!".
                RETURN TRUE.
                break.
            }
            set launchCount to launchCount + 1.
        }
    }
    if expectedEngineCount > 0 AND launchCount < expectedEngineCount {
        // Lost an engine
        print "!!! ENGINE EXPLOSION !!!".
        RETURN TRUE.
    }

    return false.
}

function getEngineCount {
    parameter stageToCheck.

    local engList is LIST().
    LIST ENGINES IN engList.
    local stageCount is 0.

    for eng in engList {
        if eng:STAGE = stageToCheck {
            set stageCount to stageCount + 1.
        }
    }

    return stageCount.
}

function releaseClamps {
    parameter clamps.
    local clamp is 0.
    for clamp in clamps {
        local clampMod is clamp:GETMODULE("ModuleRestockLaunchClamp").
        if clampMod:hasEvent("release clamp") {
            clampMod:doEvent("release clamp").
        }
    }
    print "Released clamps!".
}

function MunLaunch {

    parameter targetInclination.
    parameter targetAltitude.

    print " ".
    print "Launching from Mun - best TWR is ~4. Press any key when ready.".
    wait until Terminal:Input:haschar. 

    // Mun - we want to get on the horizon asap, as soon as altitude is safe
    local pitchStartSpeed is 5.
    local safeAltitude is 350.
    local safePitchMun IS {
        if getHeight() < safeAltitude {
            return 75.
        }
        return 10.
    }.
    local mathThrottleMun IS {
        return "MAX".
    }.

    doLaunch(targetInclination, targetAltitude, pitchStartSpeed, safePitchMun, mathThrottleMun).    
}

function MinmusLaunch {

    parameter targetInclination.
    parameter targetAltitude.

    print " ".
    print "Launching from Minmus - best TWR is ~4. Press any key when ready.".
    wait until Terminal:Input:haschar. 

    // Minmus - we want to get on the horizon asap, as soon as altitude is safe
    local pitchStartSpeed is 5.
    local safeAltitude is 250.
    local safePitchMinmus IS {
        if getHeight() < safeAltitude {
            return 85.
        }
        return 5.
    }.
    local mathThrottleMinmus IS {
        return "MAX".
    }.

    doLaunch(targetInclination, targetAltitude, pitchStartSpeed, safePitchMinmus, mathThrottleMinmus).    
}

function doLaunch {
    parameter targetInclination.
    parameter targetAltitude.
    parameter pitchStartSpeed.
    parameter pitchFunction.
    parameter throttleFunction.
    parameter rollAttitude IS "".
    
    local targetGroundVelocity is 2000.

    // Half-pitch is where we'd like the angle to be 45degrees
    //(cos(1/((x/10)+1/PI)) + 1) / 2
    local pitch is 90.
    local targetHeading is adjustedHeading(targetInclination, targetGroundVelocity, ship:VELOCITY:ORBIT:MAG).
    local finalHeading is trueHeading(targetInclination).
    local targetThrottle is 1.
    local currentRoll is 270.
    lock targetThrottle to setTWR(throttleFunction()).
    local errorAngle is 0.
    lock errorAngle to VANG(FACING:VECTOR, HEADING(targetHeading, pitch):VECTOR).

    // Set roll angle
    if rollAttitude = "i" {
        set currentRoll to 180.
    } else if rollAttitude = "n" {
        set currentRoll to 0.
    }

    local launchCount is getEngineCount(ship:stageNum).
    lock steering to HEADING(0, 90, 0).
    lock throttle to targetThrottle.
    sas off.
    wait 0.4.

    // Did all the engines start once throttled up?
    if wasThereAnEngineFailure(launchCount) {
        print "Shutting everything down and exiting.".
        set targetThrottle to 0.
        unlock throttle.
        unlock steering.
        sas on.
        RETURN.
    }

    // Are there launch clamps?
    local clamps is SHIP:PARTSNAMED("launchClamp1").
    if clamps:LENGTH > 0 {
        local launchTWR is 0.
        lock launchTWR to getCurrentTWR().
        // Yes - wait for TWR to get over 1
        wait until launchTWR > 1.1.
        // Stage those clamps
        releaseClamps(clamps).
    }

    // Pick up speed before turning
    until ship:verticalspeed > pitchStartSpeed {
        if errorAngle > 10 {
            print errorAngle + " Degrees off trajectory. Aborting.".
            if (ship:altitude < 18000) {
                ABORT ON.
            }
            RETURN.
        }
    }

    print "Begin pitching...".

    lock steering to HEADING(targetHeading, pitchFunction(), currentRoll).
    lock errorAngle to VANG(FACING:VECTOR, HEADING(targetHeading, pitchFunction()):VECTOR).
    // Are there fairings?
    local fairings is SHIP:PARTSNAMEDPATTERN("fairing").
    local stageFairings is false.
    if fairings:LENGTH > 0 {
        local thisFairing is 0.
        for thisFairing in fairings {
            if thisFairing:hasmodule("ModuleProceduralFairing") {
                if thisFairing:GetModule("ModuleProceduralFairing"):hasevent("Deploy") {
                    set stageFairings to true.
                    print "Will deploy fairing early, if under power.".
                    break.
                }
            }
        }
    }
    // Is there a launch escape system to ditch?
    local escapesystems is SHIP:PARTSNAMEDPATTERN("LaunchEscapeSystem").
    local ditchEscapeSystem is false.
    local setPrograde is true.
    if escapesystems:LENGTH > 0 {
        set ditchEscapeSystem to true.
        print "Will release the launch escape system.".
    } else {
        set escapesystems to SHIP:PARTSNAMEDPATTERN("engine-les").
        if escapesystems:LENGTH > 0 {
            set ditchEscapeSystem to true.
            print "Will release the launch escape system.".
        }
    }

    until ship:apoapsis > targetAltitude {
        // Watch for getting too far off angle
        if errorAngle > 15.0 {
            print errorAngle + " degrees off trajectory. Aborting.".
            if (ship:altitude < 18000) {
                ABORT ON.
            }
            RETURN.
        }
        if ship:GROUNDSPEED > targetGroundVelocity AND setPrograde {
            // Switch to prograde
            set setPrograde to false.
            lock steering to bestPrograde(currentRoll).
            lock errorAngle to VANG(FACING:VECTOR, ship:prograde:VECTOR).
        }
        if ship:altitude > 52000 AND stageFairings {
            // Only do this once
            set stageFairings to false.
            local thisFairing is 0.
            print "Deploying fairings.".
            for thisFairing in fairings {
                if thisFairing:hasmodule("ModuleProceduralFairing") {
                    if thisFairing:GetModule("ModuleProceduralFairing"):hasEvent("Deploy") {
                        thisFairing:GetModule("ModuleProceduralFairing"):doEvent("Deploy").
                    }
                }
            }
        }
        if ship:altitude > 22000 AND ditchEscapeSystem {
            local thisLES is 0.
            set ditchEscapeSystem to false.
            print "Ditching LES.".
            for thisLES in escapesystems {
                if thisLES:hasmodule("ModuleEnginesFX") {
                    if thisLES:GetModule("ModuleEnginesFX"):hasevent("Activate Engine") {
                        thisLES:GetModule("ModuleEnginesFX"):doEvent("Activate Engine").
                    }
                }
                if thisLES:hasmodule("ModuleDecouple") {
                    if thisLES:GetModule("ModuleDecouple"):hasevent("Decouple") {
                        thisLES:GetModule("ModuleDecouple"):doEvent("Decouple").
                    }
                }
            }
        }
    }
    print "Engine cut-off. Coasting to apoasis.".

    // Coast to apoapsis
    set targetThrottle to 0.
    // If it got missed.
    lock steering to bestPrograde(currentRoll).

    if ditchEscapeSystem {
        // Missed this under power
        local thisLES is 0.
        set ditchEscapeSystem to false.
        print "Ditching LES.".
        for thisLES in escapesystems {
            if thisLES:hasmodule("ModuleEnginesFX") {
                if thisLES:GetModule("ModuleEnginesFX"):hasevent("Activate Engine") {
                    thisLES:GetModule("ModuleEnginesFX"):doEvent("Activate Engine").
                }
            }
            if thisLES:hasmodule("ModuleDecouple") {
                if thisLES:GetModule("ModuleDecouple"):hasevent("Decouple") {
                    thisLES:GetModule("ModuleDecouple"):doEvent("Decouple").
                }
            }
        }
    }

    // Wait to exit atmosphere to calculate circular orbit.
    if body:ATM:EXISTS {
        until ship:altitude >= body:ATM:HEIGHT {
            if ship:altitude > 68000 AND stageFairings {
                // Missed deploying under power
                set stageFairings to false.
                local thisFairing is 0.
                print "Deploying fairings.".
                for thisFairing in fairings {
                    if thisFairing:hasmodule("ModuleProceduralFairing") {
                        if thisFairing:GetModule("ModuleProceduralFairing"):hasEvent("Deploy") {
                            thisFairing:GetModule("ModuleProceduralFairing"):doEvent("Deploy").
                        }
                    }
                }
            }
        }
        // Toggle deployables - action group 10/0. Use Lights if only basic is available
        AG10 ON.
        LIGHTS ON.
    } else {
        wait 0.1.   // Have to wait so we aren't under acceleration.
        set warp to 2.
        wait until ship:orbit:ETA:apoapsis < 120.
        set warp to 0.
        wait until kuniverse:timewarp:issettled.
    }

    // Circularlize
    createCircularMan("apoapsis").
    doNode(currentRoll-90).

    unlock steering.
    unlock throttle.

    print " ".
    print "Orbital insertion complete".
}

function bestPrograde {
    parameter currentRoll.
    if NAVMODE = "SURFACE" {
        return ship:srfprograde + R(0, 0, currentRoll).
    } else if NAVMODE = "ORBIT" {
        return ship:prograde + R(0, 0, currentRoll).
    }
}

function adjustedHeading {
    parameter targetInclination.
    parameter targetVelocity.
    parameter surfaceVelocity.
    local roughHeading is 90 - targetInclination.
    if (roughHeading < 0) {
        // Negatives loop around on the circle.
        set roughHeading to 360 - roughHeading.
    }
    local triAng is abs(90 - roughHeading).
    // Solving the ASS triangle with Law of Sines
    local correction is arcsin(surfaceVelocity * sin(triAng) / targetVelocity).
    if targetInclination > 0 {
        set correction to -1 * correction.
    }
    return roughHeading + correction.
}

function trueHeading {
    parameter targetInclination.
    local roughHeading is 90 - targetInclination.
    if (roughHeading < 0) {
        // Negatives loop around on the circle.
        set roughHeading to 360 - roughHeading.
    }
    return roughHeading.
}


function setTWR {
    parameter targetTWR.

    local limit is 1.
    if targetTWR <> "MAX" {
        local currentTWR is getCurrentTWR().
        if (currentTWR = 0) {
            return 1.
        }
        set limit to targetTWR / currentTWR.
    }
    return limit.
}

//parameter targetInclination.
///parameter targetAltitude.
//main(targetInclination, targetAltitude).
main().
