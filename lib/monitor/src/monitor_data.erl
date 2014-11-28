% This file is part of "Enms" (http://sourceforge.net/projects/enms/)
% Copyright (C) 2012 <Sébastien Serre sserre.bx@gmail.com>
% 
% Enms is a Network Management System aimed to manage and monitor SNMP
% target, monitor network hosts and services, provide a consistent
% documentation system and tools to help network professionals
% to have a wide perspective of the networks they manage.
% 
% Enms is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% Enms is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with Enms.  If not, see <http://www.gnu.org/licenses/>.
-module(monitor_data).
-behaviour(gen_server).
-include("include/monitor.hrl").

% GEN_SERVER
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([
    start_link/0
]).

% API
-export([
    write_target/1,
    write_probe/1,
    write_job/1
]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).



%%----------------------------------------------------------------------------
%% GEN_SERVER CALLBACKS
%%----------------------------------------------------------------------------
init([]) ->
    init_tables(),
    mnesia:subscribe({table, target, detailed}),
    mnesia:subscribe({table, probe,  detailed}),
    mnesia:subscribe({table, job,    detailed}),
    {ok, state}.

handle_call(_Call, _From, state) ->
    {noreply, state}.

handle_cast(_R, S) ->
    {noreply, S}.


handle_info({mnesia_table_event, {write, target, Target, [], _ActivityId}}, S) ->
    handle_target_create(Target),
    {noreply, S};
handle_info({mnesia_table_event, {write, target, NewRecord, OldRecord, _ActivityId}}, S) ->
    handle_target_update(NewRecord, OldRecord),
    {noreply, S};
handle_info({mnesia_table_event, {write, probe, NewRecord, [], _ActivityId}}, S) ->
    ?LOG({"handle_info write", probe, NewRecord}),
    % handle_probe_create
    {noreply, S};
handle_info({mnesia_table_event, {write, probe, NewRecord, _OldRecords, _ActivityId}}, S) ->
    ?LOG({"handle_info write", probe, NewRecord}),
    % handle_probe_update
    {noreply, S};
handle_info({mnesia_table_event, {delete, Table, What, _OldRecords, _ActivityId}}, S) ->
    ?LOG({"handle_info delete ", Table, What}),
    {noreply, S};

handle_info(_I, S) ->
    ?LOG({"handle info: ", _I}),
    {noreply, S}.

terminate(_R, state) ->
    normal.

code_change(_O, S, _E) ->
    {ok, S}.

% MNESIA events
handle_target_create(#target{global_perm = Perm} = Target) ->
    Pdu = infoTargetCreate(Target),
    supercast_channel:emit(?MASTER_CHANNEL, {Perm, Pdu}).

handle_target_update(_,_) -> ok.

    


% MNESIA init
init_tables() ->
    Tables = mnesia:system_info(tables),
    DetsOpts = [
        {auto_save, 5000}
        %{keypos, 2}
    ],
    case lists:member(target, Tables) of
        true -> ok;
        false ->
            {atomic,ok} = mnesia:create_table(
                target,
                [
                    {attributes, record_info(fields, target)},
                    {disc_copies, [node()]},
                    {storage_properties,
                        [
                            {dets, DetsOpts}
                        ]
                    }

                ]
            )
    end,
    case lists:member(probe, Tables) of
        true -> ok;
        false ->
            {atomic,ok} = mnesia:create_table(
                probe,
                [
                    {attributes, record_info(fields, probe)},
                    {disc_copies, [node()]},
                    {index, [belong_to]},
                    {storage_properties,
                        [
                            {dets, DetsOpts}
                        ]
                    }
                ]
            )
    end,
    case lists:member(job, Tables) of
        true -> ok;
        false ->
            {atomic,ok} = mnesia:create_table(
                job,
                [
                    {attributes, record_info(fields, job)},
                    {index, [belong_to]},
                    {disc_copies, [node()]},
                    {storage_properties,
                        [
                            {dets, DetsOpts}
                        ]
                    }
                ]
            )
    end.

% MNESIA write
write_target(Target) ->
    mnesia:transaction(fun() -> mnesia:write(Target) end).

write_probe(Probe) ->
    mnesia:transaction(fun() -> mnesia:write(Probe) end).

write_job(Job) ->
    mnesia:transaction(fun() -> mnesia:write(Job) end).

% PDUS
infoTargetCreate(#target{id=Id, properties=Prop}) ->
    AsnProps = lists:foldl(fun({K,V}, Acc) -> 
        [{'Property', K, V} | Acc]
    end, [], Prop),
    {modMonitorPDU,
        {fromServer,
            {infoTarget,
                {'InfoTarget',
                    atom_to_list(Id),
                    AsnProps,
                    [],
                    create}}}}.