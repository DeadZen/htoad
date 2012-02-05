-module(htoad_host).
-include_lib("htoad/include/htoad.hrl").
-include_lib("htoad/include/toadie.hrl").
-include_lib("htoad/include/stdlib.hrl").

-neg_rule({init, [{htoad_argument, {host, '__IGNORE_UNDERSCORE__'}}]}).

-rules([init, init_with_hostname_overriden, linux]).

init_with_hostname_overriden(Engine, #init{}, {htoad_argument, {host, Hostname}}) ->
    initialize(Engine, Hostname).
    
init(Engine, #init{}) when not {rule, [{htoad_argument, {host, _}}]} ->
    initialize(Engine, hostname()).

-define(LINUX_DISTRO_SHELL,
        "([ -f /etc/lsb-release ] && [ `cat /etc/lsb-release | grep DISTRIB_ID` = DISTRIB_ID=Ubuntu ] && printf Ubuntu) ||
         ([ -f /etc/redhat-release ] && [ `cat /etc/redhat-release | grep RedHat | wc -l` = 1 ] && printf RedHat) ||
         ([ -f /etc/redhat-release ] && [ `cat /etc/redhat-release | grep CentOS | wc -l` = 1 ] && printf CentOS)").

linux(Engine, {operating_system_name, linux}) ->
    Shell = #shell{ cmd = ?LINUX_DISTRO_SHELL },
    lager:debug("Detecting Linux distribution"),
    htoad:assert(Engine, [Shell,
                          htoad_utils:on({match,
                                          [{{output, Shell, '$1'},
                                            [],
                                            ['$1']}]},
                                         {linux_distribution, '_'})]).

%% private

initialize(Engine, Hostname) ->
    {OsFamily, OsName} = os:type(),
    OsVersion = os:version(),
    Engine1 = htoad:assert(Engine, [{host, Hostname},
                                    {operating_system_type, OsFamily},
                                    {operating_system_name, OsName},
                                    {operating_system_version, OsVersion}]),
    lager:debug("Hostname: ~s",[Hostname]),
    lager:debug("Operating system type: ~p",[OsFamily]),
    lager:debug("Operating system name: ~p",[OsName]),
    lager:debug("Operating system version: ~p",[OsVersion]),
    lager:debug("Initialized htoad_host"),
    Engine1.

hostname() ->
    {Host, Domain} = {inet_db:gethostname(),inet_db:res_option(domain)},
    Host ++ "." ++ Domain.
