@LAZYGLOBAL OFF.

// Experimental hoverslam script
runoncepath("0:landerscripts").

function main {
    print "Ready to start landing sequence with the 'L' key. Cancel with any other key.".
    local inputchar to "".
    wait until Terminal:Input:haschar. 
    set inputchar to Terminal:Input:getchar().
    if inputchar = "l" {
        doDeorbit().
        wait 0.
        doLanding().
    }
}

function doDeorbit {
    sas off.
    lock steering to srfretrograde.
    wait 3.
    print "Deorbit burn start...".

    until ship:groundspeed < 50 {
        lock throttle to 1.
    }
    lock throttle to 0.
    print "Deorbit burn complete.".
} 

main().