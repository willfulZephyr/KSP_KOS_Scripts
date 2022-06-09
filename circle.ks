@LAZYGLOBAL OFF.

// Adds a circularization manuever to the ship.
run once common.

function main {
    parameter targetNode.
    parameter runNode.
    if targetNode:STARTSWITH("a") {
        createCircularMan("apoapsis").
    } else if targetNode:STARTSWITH("p") {
        createCircularMan("periapsis").
    } else {
        print "Cannot circularize at " + targetNode.
        return.
    }
    if (runNode:STARTSWITH("y")) {
        doNode(0).
        print "The Circle is complete.".
    } else {
        print "Maneuver node created.".
    }
}

parameter targetNode.
parameter runNode is "n".
main(targetNode, runNode).