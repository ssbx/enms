{application, errd4j,
    [
        {description, "Erlang binding to java rrd4j"},
        {vsn, "0.1.0"},
        {modules, [
                errd4j,
                errd4j_sup,
                errd4j_app
            ]
        },
        {registered, 
            [
                errd4j,
                errd4j_sup
            ]
        },
        {applications, 
            [kernel, stdlib]
        },
        {start_phases, []},
        {mod, {errd4j_app, []}}
    ]
}.