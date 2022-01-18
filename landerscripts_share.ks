@LAZYGLOBAL OFF.
run once engine_lex.

function getLandingHeight {
    local leg_parts is "".
    // All the normal landing legs have LandingLeg in their name. Switch to tagging if need more specific
    set leg_parts to ship:PARTSNAMEDPATTERN("LandingLeg").
    local minHeight is 1000000.
    // Find the leg closest to the ground
    for leg in leg_parts {
        local bounds_box is leg:bounds.
        local thisLegHeight is bounds_box:BOTTOMALTRADAR.
        set minHeight to MIN(thisLegHeight, minHeight).
    }
    return MAX(minHeight, 0.01).
}

function doLanding {
    lock height to getLandingHeight().
    lock g to body:mu / (height + body:radius)^2.
    lock maxDecel to (ship:availablethrust / ship:mass) - g.
    local limit is 0.
    // Nerf thrust if very high - it can make it wait too long where missing a tick messes things up
    if (maxDecel > 5) {
        set limit to 400 / maxDecel.
        run_engine_function("setLimit", limit).
    }
    lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).
    lock idealthrottle to stopDist / height.
    lock impacttime to height / abs(ship:verticalspeed).

    // Wait a bit, so we're not wasting fuel against gravity.
    until (idealthrottle > 0.5) OR (stopDist * 1.1 > height) {
        // Remove once comfortable that this works.
        printLanding("Waiting to start landing.", height, stopDist, idealthrottle, impacttime, maxDecel, limit).
    }

    lock throttle to idealthrottle.
    lock altitudeCondition to height < 1.
    lock verticalSpeedCondition to ship:verticalspeed > -0.000001.

    when impacttime < 5 then { gear on. }
    until altitudeCondition or verticalSpeedCondition {
        // Remove once comfortable
        printLanding("Firing thrusters to land.", height, stopDist, idealthrottle, impacttime, maxDecel, limit).
    }

    lock throttle to 0.
    wait 0.1.
    unlock throttle.
    unlock steering.
    sas on.
    printLanding("Landed?", height, stopDist, idealthrottle, impacttime, maxDecel, limit).

}

function doHover {
    // Pass in the target altitude
    parameter target_alt.
    local HOVERPID is 0.

    // Throttle up when below target altitude, throttle down when above
    // target altitude, trying to hover:
    set HOVERPID to PIDLOOP(
        50,  // adjust throttle 0.1 per 5m in error from desired altitude.
        0.1, // adjust throttle 0.1 per second spent at 1m error in altitude.
        30,  // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
        0,   // min possible throttle is zero.
        1    // max possible throttle is one.
    ).
    set HOVERPID:SETPOINT to target_alt.
    local mythrot is 0.
    lock throttle to mythrot.
    lock height to getLandingHeight().
    print "height - target: " + target_alt + " current: " + height.
    rcs on.
    sas off.
    until not rcs {
        sas off.
        lock steering to up.
        lock mythrot to HOVERPID:UPDATE(TIME:SECONDS, height).
        wait 0.
    }
    sas on.
    lock throttle to 0.
    unlock steering.
    unlock throttle.
}

function printLanding {
    parameter message.
    parameter height.
    parameter stopDist.
    parameter idealthrottle.
    parameter impacttime.
    parameter maxDecel.
    parameter limit.

    CLEARSCREEN.
    print message.
    print " ".
    print "    altitude " + round(ship:altitude, 2).
    print "    terrain  " + round(ship:geoposition:terrainheight, 2).
    print "    bottom radar  " + round(ship:BOUNDS:bottomaltradar, 2).
    print "Height:      " + round(height, 2).
    print "  decending at " + round(ship:verticalspeed, 2).
    print "  impact in " + round(impacttime, 1).
    print " ".
    print "Stopping distance is " + round(stopDist, 2).
    print "  at throttle percent " + round(idealthrottle, 2).
    print "  max is " + round(maxDecel, 2).
    if (limit > 0) {
        print " ".
        print "NOTE: Too much thrust, using a limit of " + limit + " percent.".
    }
}