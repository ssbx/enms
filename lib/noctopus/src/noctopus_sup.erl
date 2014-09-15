% @private
-module(noctopus_sup).
-behaviour(supervisor).

-export([
    start_link/0
]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    {ok, 
        {
            {one_for_one, 10, 60},
            [
                {
                    snmpman_app,
                    {snmpman_app, start, [normal,[]]},
                    permanent,
                    2000,
                    supervisor,
                    [snmpman_app]
                },
                {
                    monitor_app,
                    {monitor_app, start, [normal,[]]},
                    permanent,
                    2000,
                    supervisor,
                    [monitor_app]
                }
            ]
        }
    }.
