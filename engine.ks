// Scripts for managing the engines quickly.
@LAZYGLOBAL OFF.
run once engine_lex.

function main {
    parameter func.
    parameter optionalParm.

    if func = "" {
        return.
    }

    run_engine_function(func, optionalParm).
}

parameter func is "".
parameter optionalParm is 0.
main(func, optionalParm).