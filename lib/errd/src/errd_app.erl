%%%-------------------------------------------------------------------
%% @copyright Geoff Cant
%% @author Geoff Cant <nem@erlang.geek.nz>
%% @doc Erlang RRDTool OTP App
%% @end
%%%-------------------------------------------------------------------
-module(errd_app).

-behaviour(application).

%% Application callbacks
-export([
    start/2, 
    start_phase/3,
    stop/1]).

%%====================================================================
%% Application callbacks
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start(Type, StartArgs) -> {ok, Pid} |
%%                                     {ok, Pid, State} |
%%                                     {error, Reason}
%% Description: This function is called whenever an application 
%% is started using application:start/1,2, and should start the processes
%% of the application. If the application is structured according to the
%% OTP design principles as a supervision tree, this means starting the
%% top supervisor of the tree.
%%--------------------------------------------------------------------
start(_Type, _StartArgs) ->
    errd_sup:start_link().

start_phase(initialize_tracker_loggers, normal, []) ->
    ok                  = errd_server_sup:create_named_instance(rrd_tracker),
    {ok, TargetDataDir} = application:get_env(tracker, targets_data_dir), 
    {ok, _}             = errd_server:cd(rrd_tracker, TargetDataDir),
    ok.
%%--------------------------------------------------------------------
%% Function: stop(State) -> void()
%% Description: This function is called whenever an application
%% has stopped. It is intended to be the opposite of Module:start/2 and
%% should do any necessary cleaning up. The return value is ignored. 
%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================

% vim: set ts=4 sw=4 expandtab:
