@LAZYGLOBAL OFF.

// Adds a circularization manuever to the ship.
run once common.

function main {
    parameter targetNode.
    if targetNode:STARTSWITH("a") {
        createCircularMan("apoapsis").
    } else if targetNode:STARTSWITH("p") {
        createCircularMan("periapsis").
    } else {
        print "Cannot circularize at " + targetNode.
        return.
    }
    doNode().
    print "The Circle is complete.".
}

parameter targetNode.
main(targetNode).