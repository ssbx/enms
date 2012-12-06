% This file is part of "Enms" (http://sourceforge.net/projects/enms/)
% Copyright (C) 2012 <Sébastien Serre sserre.bx@gmail.com>
% 
% Enms is a Network Management System aimed to manage and monitor SNMP
% targets, monitor network hosts and services, provide a consistent
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
-module(esnmp_user_default).

-behaviour(snmpm_user).
-include_lib("../include/esnmp.hrl").

-export([handle_error/3,
	 handle_agent/5,
	 handle_pdu/4,
	 handle_trap/3,
	 handle_inform/3,
	 handle_report/3]).

-define(DEFAULT_COMMUNITY, "unknown_agent").

handle_error(_ReqId,  {failed_processing_message, 
            {{securityError,usmStatsUnknownEngineIDs}, _Addr, _Port}}, _UserData) ->
	%io:format("received usmStatsUnknownEngineIDs from ~p port ~p~n", [_Addr, _Port]),
    ok;

handle_error(ReqId, Reason, UserData) ->
	info("received handle_error:"
	 "~n   ReqId:    ~p"
	 "~n   Reason:   ~p"
	 "~n   UserData: ~p", [ReqId, Reason, UserData]),
	ignore.


handle_agent(Addr, Port, trap, SnmpInfo, UserData) ->
    DbRec   = #snmp_trap{
        snmp_message    = SnmpInfo,
        version         = v2c,
        from_addr       = Addr,
        from_port       = Port,
        user_data       = UserData,
        tags            = [],
        permissions     = {community, ?DEFAULT_COMMUNITY}},
	{atomic, ok} = mnesia:transaction(fun() -> mnesia:write(snmp_trap, DbRec, write) end),
    %io:format("receive trap in ~p line ~p~n", [?MODULE, ?LINE]),
	ignore;

handle_agent(Addr, Port, Type, SnmpInfo, UserData) ->
	info("received handle_agent:"
	 "~n   Addr:     ~p"
	 "~n   Port:     ~p"
	 "~n   Type:     ~p"
	 "~n   SnmpInfo: ~p"
	 "~n   UserData: ~p", [Addr, Port, Type, SnmpInfo, UserData]),
	ignore.


handle_pdu(TargetName, ReqId, SnmpResponse, UserData) ->
	info("received handle_pdu:"
	 "~n   TargetName:   ~p"
	 "~n   ReqId:        ~p"
	 "~n   SnmpResponse: ~p"
	 "~n   UserData:     ~p", 
	 [TargetName, ReqId, SnmpResponse, UserData]),
	ignore.


handle_trap(_TargetName, _SnmpTrap, _UserData) ->
    %A = #snmp_trap{snmp_message = Info, from_addr = Addr, from_port = Port, user_data = SnmpUserData},
	%B = mnesia:transaction(fun() -> mnesia:write(snmp_trap, A, write) end),
    io:format("iiiiiiiiiiiinsert mnesia trap: ~p~n",[_TargetName]),
	ok.


handle_inform(TargetName, SnmpInform, UserData) ->
	info("received handle_inform:"
	 "~n   TargetName:   ~p"
	 "~n   SnmpInform: ~p"
	 "~n   UserData:   ~p", 
	 [TargetName, SnmpInform, UserData]),
	no_reply.


handle_report(TargetName, SnmpReport, UserData) ->
	info("received handle_inform:"
	 "~n   TargetName:   ~p"
	 "~n   SnmpReport: ~p"
	 "~n   UserData:   ~p", 
	 [TargetName, SnmpReport, UserData]),
	ok.

%info(A) ->
%	error_logger:info_msg(A).

info(F, A) ->
	error_logger:info_msg("SNMPM default user callback " ++ F ++ "~n", A).
