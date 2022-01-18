// Scripts for managing the engines quickly.
@LAZYGLOBAL OFF.

function make_engine_lexicon {
    parameter engList.

    return LEXICON(
        "activate", { 
            parameter optionalParm.
            FOR eng IN engList {
                eng:activate().
            }
        }, 
        "deactivate", {
            parameter optionalParm.
            FOR eng IN engList {
                eng:shutdown().
            }
        },
        "setLimit", {
            parameter limit.
            FOR eng IN engList {
                if eng:IGNITION > 0 {
                    // Only update active engines
                    set eng:thrustlimit to limit.
                }
            }
        }
    ).
}

function run_engine_function {
    parameter func.
    parameter optionalParm is 100.

    local engList is LIST().
    LIST ENGINES IN engList.
    local engine_function is make_engine_lexicon(engList).

    engine_function[func](optionalParm).

}
