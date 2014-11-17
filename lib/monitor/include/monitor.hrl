-include_lib("kernel/include/inet.hrl").
-include_lib("kernel/include/file.hrl").
-include("../supercast/include/supercast.hrl").

-define(LOG(X), io:format("{~w, ~w}: DEBUG: ~p~n", [?MODULE, ?LINE, X])).

-define(MASTER_CHANNEL, 'target-MasterChan').

-record(inspector, {
    module,
    conf
}).

-record(logger, {
    module,
    conf
}).

-record(ncheck_probe_conf, {
    executable  = undefined     :: string(),
    args        = []            :: [{any(), any()}],
    eval_perfs  = false         :: false | true
}).

-record(nagios_probe_conf, {
    executable  = undefined             :: string(),
    args        = []                    :: [{any(), any()}],
    eval_perfs  = false                 :: false | true
}).

-record(snmp_probe_conf, {
    port        = 161           :: integer(),
    version     = "v2"          :: string(), % "1" | "2c" | "3"
    seclevel    = "noAuthNoPriv" :: string(), % "authPriv", "authNoPriv", "noAuthNoPriv"
    community   = "none"        :: string(),
    usm_user    = "undefined"   :: string(),
    authkey     = none          :: none | string(),
    authproto   = "SHA"         :: string(),
    privkey     = none          :: none | string(),
    privproto   = "AES"         :: string(),
    oids        = []            :: [any()],
    method      = get           :: get | {walk, [string()], [tuple()]},
    retries     = 1             :: integer()
}).



-record(probe_return, {
    status          = 'UNKNOWN' :: 'OK' | 'UNKNOWN' | 'WARNING' | 'CRITICAL',
    % used by inspector status set

    original_reply  = "undefined" :: string(),
    % used by the text logger
 
    timestamp       = 0         :: integer(),
    key_vals        = []        :: [{string(), any()}],
    % used by inspector property set/get 
 
    reply_tuple     = undefined :: any(),
    % used by the rrd logger/walk table
 
    is_event        = false     :: true | false %
    % used by monitor_logger_events app
}).

-record(job, {
    prop
}).

-record(probe, {
    name                = undefined     :: atom(),
    pid                 = undefined     :: undefined | pid(),
    description         = ""            :: string(),
    info                = ""            :: string(),
    permissions         = #perm_conf{}  :: #perm_conf{},
    timeout             = 5             :: integer(), % seconds
    status              = 'UNKNOWN'     :: 'UNKNOWN' | atom(),
    step                = 5000          :: integer(), % milliseconds

    properties          = []            :: [{string(), any()}],
    % forward properties is a list of properties wich will be propagated
    % to the target.
    forward_properties  = []            :: [string()],

    parents             = []            :: [atom()],
    active              = true          :: true | false,

    monitor_probe_mod   = undefined     :: undefined | module(),
    monitor_probe_conf  = undefined     :: [any()],
    inspectors          = []            :: [#inspector{}],
    loggers             = []            :: [#logger{}]
}).

-record(target, {
    id          = undefined     :: atom(),
    ip          = undefined     :: string(),
    ip_version  = undefined     :: string(),
    global_perm = #perm_conf{
        read        =   ["admin"],
        write       =   ["admin"]
    },
    % sys_properties only accessible to users having write access
    sys_properties = []         :: [{atom(), string()}],
    % properties accessible to all users having read access
    properties  = []            :: [{any(), any()}],

    probes      = []            :: [#probe{}],
    jobs        = []            :: [#job{}],

    directory   = ""            :: string()
}).

-record(probe_set, {
    name,
    perm  = undefined   :: #perm_conf{},    % who is allowed to generate this
                                            % set.
    probe = []          :: [#probe{}]
}).


% RRD related. The max line accpeted by rrdtool is reached with
% a 48 ports switch. It is why we need to break rrd databases
% in little parts.
-record(rrd_binds, {
    name    = ""                :: string(),
    macro   = ""                :: string()
}).

-record(rrd_config2, {
    file,
    create,
    update,
    graphs,
    binds
}).
-record(rrd_config, {
    file    = ""                :: string(),
    create  = ""                :: string(),
    update  = ""                :: string(),
    graphs  = []                :: [string()],
    binds   = []                :: [{string(), string()}], % {replacement, macro}
    update_regexps = none       :: [any()],                % {key, re}
    file_path = none            :: string()
}).

% monitor_logger_events
-record(probe_event, {
    id          = 0                 :: integer(),
    insert_ts   = 0                 :: integer(),
    ack_ts      = 0                 :: integer(),
    status      = "undefined"       :: string(),
    textual     = "undefined"       :: string(),
    ack_needed  = true              :: true | false,
    ack_value   = "undefined"       :: string(),
    group_owner = "undefined"       :: string(),
    user_owner  = "undefined"       :: string()
}).
