-module(event).
-export([start/0, init/0, loop/0]).

start() ->
    spawn(?MODULE, init, []).

init() ->
    {foo, 'freeswitch@freeswitch'} ! register_event_handler,
    {foo, 'freeswitch@freeswitch'} ! {event, 'ALL'},
    loop().

loop() ->
    receive
        _Event  -> 
            %io:format("~p~n", [Event]),
            loop()
    end.
